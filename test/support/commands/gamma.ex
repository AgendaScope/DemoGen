defmodule DemoGen.Test.Gamma do
  use DemoGen, command_name: "gamma"

  @impl DemoGen.Command
  def run(args, context) do
    {:bool, bool_value} = Map.get(args, :bool)
    {:number, number_value} = Map.get(args, :number)
    {:string, string_value} = Map.get(args, :string)
    {:number, fourty_two} = Map.get(args, :fourty_two)

    {:ok, Map.put(context, "gamma", {bool_value, number_value, string_value, fourty_two})}
  end
end
