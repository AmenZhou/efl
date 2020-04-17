# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :efl,
  ecto_repos: [Efl.Repo]

# Configures the endpoint
config :efl, Efl.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "rb1/HYHuCiIqol5wDRX1lZHGRkMGzZ1P4a9KYXd+1vondVXLVLQFaV9lX3AkswnW",
  render_errors: [view: Efl.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Efl.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
# tell logger to load a LoggerFileBackend processes
config :logger,
  backends: [{LoggerFileBackend, :info_log}],
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# configuration for the {LoggerFileBackend, :error_log} backend
config :logger, :info_log,
  path: "./info.log",
  level: :info

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
