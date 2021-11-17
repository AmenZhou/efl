defmodule Efl.Mixfile do
  use Mix.Project

  def project do
    [app: :efl,
     version: "0.0.1",
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Efl, []},
     applications: [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :gettext,
                    :phoenix_ecto, :httpotion, :myxql, :timex, :elixlsx,
                    :mailgun, :exrm, :relx, :floki, :logger_file_backend, :conform]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 4.3"},
      {:ecto_sql, "~> 3.6.2"},
      {:myxql, "~> 0.5.1"},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 2.0"},
      {:floki, "~> 0.11.0"},
      {:httpotion, "~> 3.1.2"},
      {:timex, "~> 3.0"},
      # {:timex_ecto, "~> 3.0"},
      {:elixlsx, "~> 0.4.2"},
      {:mailgun, github: "chrismccord/mailgun"},
      {:exrm, "~> 1.0.8"},
      {:relx, "~> 3.23"},
      {:logger_file_backend, "0.0.9"},
      {:conform, "2.1.2"},
      {:erlware_commons, "~> 1.0"}
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
