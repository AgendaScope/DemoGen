defmodule DemoGen.MixProject do
  use Mix.Project

  def project do
    [
      app: :demo_gen,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:logical_file, "~> 1.0"},
      {:ergo, "~>1.0"},
      {:ecto_sql, "~>3.6"},
      {:timex, "~> 3.7", override: true}
    ]
  end
end
