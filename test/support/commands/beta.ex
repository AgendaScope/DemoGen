defmodule DemoGen.Test.Beta do
  use DemoGen, command_name: "beta"

  @impl DemoGen.Command
  def run(_args, context) do
    {:ok, Map.put(context, "beta", true)}
  end
end
