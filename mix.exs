defmodule DemoGen.MixProject do
  use Mix.Project

  def project do
    [
      app: :demo_gen,
      name: "DemoGen",
      description: description(),
      version: "0.1.7",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp description() do
    "Execute a user-written script to create a repeatable demo scenario"
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:logical_file, "~> 1.0"},
      {:ergo, "~>1.0"},
      {:ecto_sql, "~>3.6"},
      {:timex, "~> 3.7"}
    ]
  end

  defp package do
    [
      files: ~w(lib test .formatter.exs mix.exs README.md LICENSE),
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/AgendaScope/DemoGen"}
    ]
  end
end
