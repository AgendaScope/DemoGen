defmodule DemoGen.Runner do
  alias DemoGen.Parser
  alias DemoGen.Command

  def run_demo(demo_file, opts \\ []) do
    repo = Keyword.fetch!(opts, :repo)
    mod_prefix = Keyword.fetch!(opts, :prefix)
    validate_repo!(repo)

    with command_map <- build_command_map([DemoGen.Commands, mod_prefix]),
         {:ok, commands} <- Parser.parse_file(demo_file) do
      repo.transaction(fn ->
        Enum.reduce(
          commands,
          %{time: DateTime.utc_now(), command_map: command_map, repo: repo, symbols: %{}},
          &execute_command/2
        )
      end)
    end
  end

  def execute_command(
        {:command, command, args},
        %{command_map: command_map, repo: repo} = context
      ) do
    case Map.fetch(command_map, command) do
      {:ok, command_module} ->
        case Command.run(command_module, args, context) do
          {:ok, context} ->
            context

          {:error, message} ->
            repo.rollback(message)
        end

      :error ->
        repo.rollback("Unknown command: #{command}")
    end
  end

  defp build_command_map(prefixes) when is_list(prefixes) do
    prefixes
    |> Enum.map(&build_command_map/1)
    |> Enum.reduce(&Map.merge/2)
  end

  defp build_command_map(prefix) when is_atom(prefix) do
    build_command_map(Atom.to_string(prefix))
  end

  defp build_command_map(prefix) when is_binary(prefix) do
    :code.all_available()
    |> Enum.filter(fn
      {module, _, _} when is_list(module) -> true
      _ -> false
    end)
    |> Enum.map(fn {module, _, _} -> List.to_string(module) end)
    |> Enum.filter(fn module_name -> String.starts_with?(module_name, prefix) end)
    |> Enum.map(&String.to_atom/1)
    |> Enum.filter(&Code.ensure_loaded?/1)
    |> Enum.filter(fn module -> Kernel.function_exported?(module, :demogen_command_name, 0) end)
    |> Enum.map(fn module -> {module.demogen_command_name(), module} end)
    |> Map.new()
  end

  defp validate_repo!(nil), do: :ok

  defp validate_repo!(repo) when is_atom(repo) do
    IO.inspect(repo)
    Code.ensure_loaded!(repo)

    unless Ecto.Repo in (repo.__info__(:attributes)[:behaviour] || []) do
      raise ArgumentError, "Expected repo to be an Ecto.Repo, got: #{inspect(repo)}"
    end

    :ok
  end

  defp validate_repo!(repo) do
    raise ArgumentError, "Expected repo to be a module, got: #{inspect(repo)}"
  end
end
