defmodule KeywordValidator.MixProject do
  use Mix.Project

  @version "2.1.0"

  def project do
    [
      app: :keyword_validator,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "KeywordValidator",
      docs: docs(),
      aliases: aliases(),
      preferred_cli_env: preferred_cli_env()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    Simple validation for keyword lists.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Nicholas Sweeting"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/nsweeting/keyword_validator"}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_url: "https://github.com/nsweeting/keyword_validator"
    ]
  end

  defp aliases do
    [
      setup: [
        "local.hex --if-missing --force",
        "local.rebar --if-missing --force",
        "deps.get"
      ],
      ci: [
        "setup",
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "test"
      ]
    ]
  end

  defp preferred_cli_env do
    [
      ci: :test
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.37", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
