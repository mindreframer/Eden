defmodule Eden.Mixfile do
  use Mix.Project

  def project do
    [
      app: :eden,
      version: "2.0.0",
      elixir: "~> 1.5",
      description: description(),
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    if Mix.env() != :prod do
      [applications: [:array, :cortex]]
    else
      [applications: [:array]]
    end
  end

  defp deps do
    [
      {:array, github: "blogscot/elixir-array"},
      {:ex_doc, "~> 0.7", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev},
      {:cortex, "~> 0.5", only: [:dev, :test]},
    ]
  end

  defp description do
    """
    edn (extensible data notation) encoder/decoder implemented in Elixir.
    """
  end

  defp package do
    [
      files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      contributors: ["Juan Facorro"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/jfacorro/Eden/",
        "edn format" => "https://github.com/edn-format/edn"
      }
    ]
  end
end
