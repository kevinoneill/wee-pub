defmodule WeePub.Mixfile do
  use Mix.Project

  def project do
    [
      app: :weepub,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),

      # Hex Details
      name: "WeePub",
      description: "A light weight pub/sub system",
      source_url: "https://github.com/kevinoneill/wee-pub",
      package: package(),
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {WeePub.Application, []}
    ]
  end

  defp deps do
    [
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
    ]
  end

  defp package() do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Kevin O'Neill"],
      licenses: ["BSD-3-Clause"],
      links: %{"GitHub" => "https://github.com/kevinoneill/wee-pub"}
    ]
  end
end
