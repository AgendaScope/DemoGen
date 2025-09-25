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
    {t, delta_t} = Map.get(context, "delta")
    assert DateTime.add(t, 1, :day) == delta_t
    assert Map.get(context, "gamma") == {true, 42, "What is six times seven?", 42}
  end
end
