defmodule Barracuda.Mixfile do
  use Mix.Project

  def project do
    [app: :barracuda,
     version: "0.1.0",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     description: description(),
     package: package()]
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
  
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp description do
    """
    Is a library that allows generation of HTTP clients in a declarative manner.
    """
  end

  defp package do
    [# These are the default files included in the package
     name: :barracuda,
     files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
     maintainers: ["Alex Shneyderman"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/ashneyderman/barracuda"}]
  end
end
