defmodule Efl.Mixfile do
  use Mix.Project

  def project do
    [app: :efl,
     version: "0.0.1",
     elixir: "~> 1.17",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps(),
]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Efl, []},
     applications: [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :gettext,
                    :phoenix_ecto, :ecto_sql, :httpotion, :myxql, :timex, :elixlsx,
                    :floki, :conform, :poison, :tesla, :swoosh]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:myxql, "~> 0.6.0"},
      {:phoenix_html, "~> 2.14"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:gettext, "~> 0.23"},
      {:plug_cowboy, "~> 2.6"},
      {:floki, "~> 0.35"},
      {:httpotion, "~> 3.1.2"},
      {:timex, "~> 3.7"},
      # {:timex_ecto, "~> 3.0"},
      {:elixlsx, "~> 0.4.2"},
      # {:mailgun, "~> 0.1.2"},  # Commented out due to dependency conflicts
      # {:exrm, "~> 1.0.8"},  # Commented out due to compilation issues
      # {:relx, "~> 3.5"},   # Commented out due to compilation issues
      {:conform, "~> 2.5"},
      {:tesla, "~> 1.7"},
      {:hackney, "~> 1.18"},
      {:jason, "~> 1.4"},
      {:poison, "~> 4.0"},
      {:swoosh, "~> 1.17"},
      {:multipart, "~> 0.4"},
      {:plug, "~> 1.18"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     test: ["ecto.create --quiet", "ecto.migrate", "test"]]
  end

end
