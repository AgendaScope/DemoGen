defmodule DemoGen.TimestampHelpers do
  @moduledoc """
  Helpers for setting timestamps on entities after they've been created via demo
  commands. Uses SQL directly.
  """

  @doc """
  Sets timestamps on an entity using direct SQL update.

  This function updates the inserted_at and updated_at fields of an entity
  to use the provided time, then returns the entity struct with the
  updated timestamp fields.

  ## Parameters

  - `entity`: The Ecto struct that was just created/updated
  - `time`: The DateTime to use for inserted_at and updated_at
  - `repo`: The app Repo Module

  ## Examples

      # In a demo command after calling your context function:
      with {:ok, item} <- Items.create_item(user, attrs) do
        updated_item = TimestampHelpers.with_timestamps(item, time, MyApp.Repo)
        {:ok, %{context | symbols: Map.put(symbols, :item, updated_item)}}
      end

      # Works with any entity type:
      updated_user = TimestampHelpers.with_timestamps(user, time, MyApp.Repo)
      updated_org = TimestampHelpers.with_timestamps(org, time, MyApp.Repo)

  ## Returns
    {:ok, entity} -> entity struct with updated inserted_at and updated_at fields.
  """
  def with_timestamps(entity, time, repo) when is_struct(entity) do
    case repo.query(timestamps_query(entity), [time, time, entity.id]) do
      {:ok, _} ->
        {:ok, entity |> Map.merge(%{inserted_at: time, updated_at: time})}

      {:error, _} = err ->
        err
    end
  end

  defp timestamps_query(entity) do
    "UPDATE #{table_name(entity)} SET inserted_at = $1, updated_at = $2 WHERE id = $3"
  end

  @doc """
  Sets only the updated_at timestamp for update operations.

  Use this for demo commands that update existing entities rather than create new ones.

  ## Parameters

  - `entity`: The Ecto struct that was just updated
  - `time`: The DateTime to use for updated_at
  - `repo`: The app Repo module

  ## Examples
  with {:ok, item} <- Items.update_item(item, attrs) do
    updated_item = TimestampHelpers.with_updated_at(item, time, MyApp.Repo)
    {:ok, %{context | symbols: Map.put(symbols, :item, updated_item)}}
  end
  """
  def with_updated_at(entity, time, repo) when is_struct(entity) do
    case repo.query(timestamp_query(entity), [time, entity.id]) do
      {:ok, _} -> {:ok, entity |> Map.put(:updated_at, time)}
      {:error, _} = err -> err
    end
  end

  defp timestamp_query(entity) do
    "UPDATE #{table_name(entity)} SET updated_at = $1 WHERE id = $2"
  end

  @doc """
  Convenience function that calls a context function and sets demo timestamps.

  This combines calling your existing context function with timestamp setting
  in a single function call.

  ## Parameters

  - `context_fun`: A zero-arity function that calls your existing context function
  - `time`: The DateTime to use for timestamps
  - `repo`: The app Repo module

  ## Examples

  # Instead of calling context function + timestamp helper separately:
  with {:ok, item} <- TimestampHelpers.create_with_timestamps(
    fn -> Items.create_item(user, attrs) end,
    time,
    MyApp.Repo
  ) do
    {:ok, %{context | symbols: Map.put(symbols, :item, item)}}
  end
  """
  def create_with_timestamps(context_fun, time, repo)
      when is_function(context_fun, 0) do
    case context_fun.() do
      {:ok, entity} ->
        with {:ok, updated_entity} <- with_timestamps(entity, time, repo) do
          {:ok, updated_entity}
        end

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Similar to create_with_timestamps/3 but only sets updated_at for updates.
  """
  def update_with_timestamps(context_fun, time, repo)
      when is_function(context_fun, 0) do
    case context_fun.() do
      {:ok, entity} ->
        with {:ok, updated_entity} <- with_updated_at(entity, time, repo) do
          {:ok, updated_entity}
        end

      {:error, _} = error ->
        error
    end
  end

  defp table_name(entity) when is_struct(entity) do
    # Given an Ecto Schema struct (e.g. %User{}) return the underlying table
    # name (e.g. "users") for that schema.
    entity.__struct__.__schema__(:source)
  end
end
