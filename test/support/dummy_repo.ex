defmodule DemoGen.Test.DummyRepo do
  @behaviour Ecto.Repo

  def transaction(fun) do
    # Simply execute the function and return its result wrapped in an :ok tuple
    result = fun.()
    {:ok, result}
  end

  def rollback(reason) do
    # Just return the reason as expected by Ecto.Repo.rollback
    throw({:rollback, reason})
  end

  # Implement other required callbacks as no-ops or with test-specific behavior
  def all(_), do: []
  def get(_, _), do: nil
  def get!(_, _), do: nil
  def get_by(_, _), do: nil
  def get_by!(_, _), do: nil
  def one(_), do: nil
  def one!(_), do: nil
  def insert(_), do: {:ok, %{}}
  def insert!(_), do: %{}
  def update(_), do: {:ok, %{}}
  def update!(_), do: %{}
  def delete(_), do: {:ok, %{}}
  def delete!(_), do: %{}
  def insert_or_update(_), do: {:ok, %{}}
  def insert_or_update!(_), do: %{}
  def insert_all(_, _), do: {0, nil}
  def insert_all(_, _, _), do: {0, nil}
  def update_all(_, _), do: {0, nil}
  def update_all(_, _, _), do: {0, nil}
  def delete_all(_), do: {0, nil}
  def delete_all(_, _), do: {0, nil}
  def checkout(_, _), do: :ok
  def aggregate(_, _, _), do: 0
  def aggregate(_, _, _, _), do: 0
  def stream(_), do: Stream.map([], & &1)
  def exists?(_), do: false
end
