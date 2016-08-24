defmodule Barracuda.Mixfile do
  use Mix.Project

  def project do
    [app: :barracuda,
     version: "0.1.0",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :httpoison]]
  end

  defp deps do
    [
      {:httpoison, "~> 0.9.0"},
      {:poison, "~> 2.2"}
    ]
  end
  
  defp elixirc_paths(:test), do: ["lib", "test/support", "samples"]
  defp elixirc_paths(_),     do: ["lib"]

end
