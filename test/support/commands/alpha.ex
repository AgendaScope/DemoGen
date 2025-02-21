defmodule DemoGen.Test.Alpha do
  use DemoGen, command_name: "alpha"

  @impl DemoGen.Command
  def run(_args, context) do
    {:ok, Map.put(context, "alpha", true)}
  end
end
