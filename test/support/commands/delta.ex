defmodule DemoGen.Test.Delta do
  use DemoGen, command_name: "delta"

  @impl DemoGen.Command
  def run(args, context) do
    {:rel_time, rt_fun} = Map.get(args, :future)
    {:ok, Map.put(context, "delta", {context.time, rt_fun.(context.time)})}
  end
end
