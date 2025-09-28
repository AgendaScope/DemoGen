defmodule DemoGen.Runner do
  alias DemoGen.Parser
  alias DemoGen.Command

  @doc """
  Runs a demo from a demo file with the given options.

  This function parses and executes commands from a demo file within a repository
  transaction. It builds a command map from the provided module prefixes and
  delegates to `run_demo/3`.

  ## Parameters

  - `demo_file` - Path to the demo file containing commands to execute
  - `opts` - Keyword list of options:
    - `:repo` - Repository module (required)
    - `:prefix` - Module prefix(es) for command mapping (required)

  ## Returns

  The result of the repository transaction containing the executed commands,
  or an error tuple if parsing fails.

  ## Examples

      iex> DemoGen.Runner.run_demo("demo.dgen", repo: MyRepo, prefix: MyApp.Demo.Commands)
      {:ok, %{time: ~U[...], ...}}
  """

  def run_demo(demo_file, opts \\ []) do
    repo = Keyword.fetch!(opts, :repo)
    validate_repo!(repo)

    command_map =
      opts
      |> Keyword.fetch!(:prefix)
      |> get_mod_prefixes()
      |> build_command_map()

    run_demo(demo_file, repo, command_map)
  end

  @doc """
  Runs a demo from a demo file with an explicit repository and command map.

  This is the lower-level function that performs the actual demo execution.
  It parses the demo file and executes each command within a repository transaction,
  maintaining execution context including timestamps and symbol state.

  ## Parameters

  - `demo_file` - Path to the demo file containing commands to execute
  - `repo` - Repository module that implements Ecto.Repo behaviour
  - `command_map` - Map of command names to their corresponding command modules

  ## Returns

  - `{:ok, context}` - Success with final execution context containing timestamps,
    command map, repo, and accumulated symbols
  - `{:error, reason}` - Error if file parsing fails or transaction is rolled back

  ## Examples

      iex> command_map = %{"create_user" => MyApp.Demo.Commands.CreateUser}
      iex> DemoGen.Runner.run_demo("demo.dgen", MyRepo, command_map)
      {:ok, %{time: ~U[2024-01-01 12:00:00Z], symbols: %{user_id: 123}, ...}}

  """
  def run_demo(demo_file, repo, command_map) do
    with {:ok, commands} <- Parser.parse_file(demo_file) do
      repo.transaction(fn ->
        Enum.reduce(
          commands,
          %{time: DateTime.utc_now(), command_map: command_map, repo: repo, symbols: %{}},
          &execute_command/2
        )
      end)
    end
  end

  defp get_mod_prefixes(prefixes) when is_list(prefixes), do: [DemoGen.Commands | prefixes]
  defp get_mod_prefixes(prefix) when is_atom(prefix), do: get_mod_prefixes([prefix])

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
