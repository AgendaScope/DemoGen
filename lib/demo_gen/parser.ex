defmodule DemoGen.Parser do
  alias LogicalFile
  alias Ergo.Combinators
  alias Ergo.Terminals
  alias Ergo.Numeric

  def parse_ws(), do: Combinators.ignore(Combinators.many(Terminals.ws()))
  def parse_ows(), do: Combinators.optional(parse_ws())

  def parse_open_block(), do: Terminals.char(?{)
  def parse_close_block(), do: Terminals.char(?})
  def parse_colon(), do: Terminals.char(?:)
  def parse_plus(), do: Terminals.char(?+)
  def parse_minus(), do: Terminals.char(?-)
  def parse_dquote(), do: Terminals.char(?")
  def parse_dollar(), do: Terminals.char(?$)
  def parse_equals(), do: Terminals.char(?=)
  def parse_at(), do: Terminals.char(?@)
  def parse_open_bracket(), do: Terminals.char(?[)
  def parse_close_bracket(), do: Terminals.char(?])

  def parse_id_initial_char() do
    Terminals.char([?a..?z, ?A..?Z])
  end

  def parse_id_char() do
    Terminals.char([?a..?z, ?A..?Z, ?0..?9, ?_])
  end

  def parse_identifier() do
    Combinators.sequence(
      [
        parse_id_initial_char(),
        Combinators.many(parse_id_char())
      ],
      ast: fn [first_char, rest_chars] ->
        [first_char | rest_chars] |> List.to_string() |> String.to_atom()
      end
    )
  end

  def parse_bool_value() do
    Combinators.choice([
      Terminals.literal("true") |> Combinators.replace({:bool, true}),
      Terminals.literal("false") |> Combinators.replace({:bool, false})
    ])
  end

  def parse_symbol_value() do
    parse_identifier() |> Combinators.transform(fn symbol -> {:symbol, symbol} end)
  end

  def parse_numeric_value() do
    Numeric.number() |> Combinators.transform(fn number -> {:number, number} end)
  end

  def parse_non_dquote() do
    Combinators.sequence(
      [
        Combinators.not_lookahead(parse_dquote()),
        Terminals.any()
      ],
      ast: fn [c] -> c end
    )
  end

  def parse_string_value() do
    Combinators.sequence(
      [
        Combinators.ignore(parse_dquote()),
        Combinators.many(parse_non_dquote()),
        Combinators.ignore(parse_dquote())
      ],
      ast: fn chars ->
        {:string, chars |> List.flatten() |> List.to_string()}
      end
    )
  end

  def parse_const_ref() do
    Combinators.sequence(
      [
        Combinators.ignore(parse_dollar()),
        parse_identifier()
      ],
      ast: fn [identifier] ->
        {:const, identifier}
      end
    )
  end

  def parse_value() do
    Combinators.choice([
      parse_bool_value(),
      parse_symbol_value(),
      parse_numeric_value(),
      parse_string_value(),
      parse_const_ref()
    ])
  end

  def parse_attribute() do
    Combinators.sequence(
      [
        parse_identifier(),
        Combinators.ignore(parse_colon()),
        parse_ows(),
        parse_value(),
        parse_ows()
      ],
      ast: fn [name, value] -> {name, value} end
    )
  end

  def parse_attributes() do
    Combinators.sequence(
      [
        Combinators.ignore(parse_open_block()),
        parse_ows(),
        Combinators.many(parse_attribute()),
        Combinators.ignore(parse_close_block())
      ],
      ast: fn [attributes] ->
        Enum.reduce(attributes, %{}, fn {name, value}, attrs ->
          Map.put(attrs, name, value)
        end)
      end
    )
  end

  def parse_command() do
    Combinators.sequence(
      [
        parse_ows(),
        parse_identifier(),
        parse_ws(),
        parse_attributes()
      ],
      ast: fn [command, attributes] ->
        {:command, command, attributes}
      end
    )
  end

  def parse_const() do
    Combinators.sequence(
      [
        parse_ows(),
        Combinators.ignore(parse_dollar()),
        parse_identifier(),
        parse_ows(),
        Combinators.ignore(parse_equals()),
        parse_ows(),
        parse_value()
      ],
      ast: fn [name, value] ->
        {:const, name, value}
      end
    )
  end

  def parse_clock_expr() do
    Combinators.sequence(
      [
        parse_ows(),
        Combinators.ignore(parse_open_bracket()),
        parse_numeric_value(),
        Combinators.ignore(parse_colon()),
        parse_numeric_value(),
        Combinators.optional(
          Combinators.sequence([
            Combinators.ignore(parse_colon()),
            parse_numeric_value()
          ])
        ),
        Combinators.ignore(parse_close_bracket())
      ],
      ast: fn
        [h, m] ->
          {:command, :set_clock, %{h: h, m: m, s: {:number, 0}}}

        [h, m, s] ->
          {:command, :set_clock, %{h: h, m: m, s: s}}
      end
    )
  end

  def parse_macro_define() do
    Combinators.sequence(
      [
        parse_ows(),
        Combinators.ignore(Terminals.literal("macro")),
        parse_ws(),
        parse_identifier(),
        parse_ows(),
        Combinators.ignore(parse_equals()),
        parse_ows(),
        parse_identifier(),
        parse_ws(),
        parse_attributes()
      ],
      ast: fn [macro_name, command, attrs] ->
        {:macro, macro_name, command, attrs}
      end
    )
  end

  def parse_macro_expansion() do
    Combinators.sequence(
      [
        parse_ows(),
        Combinators.ignore(parse_at()),
        parse_identifier()
      ],
      ast: fn [macro_name] ->
        {:expand, macro_name}
      end
    )
  end

  def parser() do
    Combinators.sequence(
      [
        Combinators.many(
          Combinators.choice([
            parse_clock_expr(),
            parse_macro_define(),
            parse_const(),
            parse_command(),
            parse_macro_expansion()
          ])
        ),
        parse_ows(),
        Terminals.eoi()
      ],
      ast: fn [content] ->
        content
        |> separate_content()
        |> order_commands()
        |> expand_macros()
        |> replace_consts()
      end
    )
  end

  def order_commands(%{commands: commands_reversed} = content) do
    %{content | commands: Enum.reverse(commands_reversed)}
  end

  def expand_macros(%{commands: commands, macros: macros} = content) do
    %{
      content
      | commands:
          Enum.map(commands, fn
            {:command, _, _} = command -> command
            {:expand, macro_name} -> Map.fetch!(macros, macro_name)
          end)
    }
  end

  def replace_consts(%{commands: commands, consts: consts}) do
    commands
    |> Enum.map(fn {:command, command, attributes} ->
      {
        :command,
        command,
        Enum.reduce(
          attributes,
          %{},
          fn
            {name, {:const, const_name}}, acc ->
              Map.put(acc, name, Map.fetch!(consts, const_name))

            {name, value}, acc ->
              Map.put(acc, name, value)
          end
        )
      }
    end)
  end

  def separate_content(content) do
    Enum.reduce(
      content,
      %{macros: %{}, consts: %{}, commands: []},
      fn
        {:macro, name, command, attrs}, %{macros: macros} = acc ->
          %{acc | macros: Map.put(macros, name, {:command, command, attrs})}

        {:command, _, _} = command, %{commands: commands} = acc ->
          %{acc | commands: [command | commands]}

        {:expand, _} = command, %{commands: commands} = acc ->
          %{acc | commands: [command | commands]}

        {:const, name, value}, %{consts: consts} = acc ->
          %{acc | consts: Map.put(consts, name, value)}
      end
    )
  end

  def parse(input) when is_binary(input) do
    case Ergo.parse(parser(), input) do
      %{status: :ok, ast: command_list} ->
        {:ok, command_list}

      %{status: {:error, reasons}} ->
        {:error, reasons}
    end
  end

  def parse(%LogicalFile{} = source) do
    parse(to_string(source))
  end

  def parse_file(source_path) when is_binary(source_path) do
    base_path = Path.expand(Path.dirname(source_path))
    file_name = Path.basename(source_path)
    source = LogicalFile.read(base_path, file_name, [DemoGen.CommentMacro.invocation([])])
    parse(source)
  end
end
