defmodule SoupAndNutz.MixProject do
  use Mix.Project

  def project do
    [
      app: :soup_and_nutz,
      version: "0.2.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_coverage: :coveralls,
      coveralls_options: [minimum_coverage: 80]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {SoupAndNutz.Application, []},
      extra_applications: [:logger, :runtime_tools] ++ if(Mix.env() == :test, do: [:wallaby], else: [])
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.21"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      # {:heroicons,
      #  github: "tailwindlabs/heroicons",
      #  tag: "v2.1.1",
      #  sparse: "optimized",
      #  app: false,
      #  compile: false,
      #  depth: 1},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},
      {:excoveralls, "~> 0.18", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:money, "~> 1.12"},
      {:bcrypt_elixir, "~> 3.0"},
      # E2E Testing dependencies
      {:wallaby, "~> 0.30", runtime: false, only: :test},
      {:ex_machina, "~> 2.7", only: :test},
      {:faker, "~> 0.17", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "test.coverage": ["coveralls"],
      "test.coverage.html": ["coveralls.html"],
      "test.coverage.json": ["coveralls.json"],
      # E2E Testing aliases
      "test.e2e": ["ecto.create --quiet", "ecto.migrate --quiet", "test --only feature"],
      "test.unit": ["ecto.create --quiet", "ecto.migrate --quiet", "test --exclude feature"],
      "test.all": ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind soup_and_nutz", "esbuild soup_and_nutz"],
      "assets.deploy": [
        "tailwind soup_and_nutz --minify",
        "esbuild soup_and_nutz --minify",
        "phx.digest"
      ]
    ]
  end
end
