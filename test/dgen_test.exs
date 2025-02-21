defmodule DemoGenTest do
  use ExUnit.Case
  doctest DemoGen

  alias DemoGen.Runner

  test "greets the world" do
    {:ok, context} =
      Runner.run_demo("test/support/test.dgen",
        prefix: DemoGen.Test,
        repo: DemoGen.Test.DummyRepo
      )

    assert Map.get(context, "alpha") == true
    assert Map.get(context, "beta") == true
  end
end
