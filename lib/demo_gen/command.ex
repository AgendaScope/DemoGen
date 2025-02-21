defmodule DemoGen.Command do
  alias Ecto.Changeset

  def run(command_module, args, %{time: _t, symbols: %{} = _s} = context) do
    apply(command_module, :run, [args, context])
  end

  def lookup_symbol(symbols, args, key)
      when is_map(symbols) and is_map(args) and is_atom(key) do
    {:symbol, sym_key} = Map.fetch!(args, key)
    Map.fetch!(symbols, sym_key)
  end

  def set_timestamps(change, t) do
    change
    |> set_inserted_timestamp(t)
    |> set_updated_timestamp(t)
  end

  def set_inserted_timestamp(change, t) do
    Changeset.cast(change, %{"inserted_at" => t}, [:inserted_at])
  end

  def set_updated_timestamp(change, t) do
    Changeset.cast(change, %{"updated_at" => t}, [:updated_at])
  end

  @callback run(args :: map(), context :: map()) :: tuple()
end
