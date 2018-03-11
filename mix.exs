defmodule Excoverage.Mixfile do
  use Mix.Project

  def project do
    [
      app: :excoverage,
      test_coverage: [tool: Excoverage],
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env == :test,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Excoverage"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 0.4", only: [:dev]},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description() do
    "A tool for calculating test coverage written from the beginning to the end in elixir. Only function coverage support - WIP: lines and branches."
  end

  defp package() do
    [
      name: "excoverage",
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["RJSkorski"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/RJSkorski/excoverage"}
    ]
  end
end
