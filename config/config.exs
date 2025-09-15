# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

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
config :logger,
  backends: [:console, {Efl.LoggerBackend, :info_log}]

config :logger, :console,
  format: "$time $date $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger, :info_log,
  level: :info

config :tesla, adapter: Tesla.Adapter.Hackney

# Configure JSON library for Phoenix
config :phoenix, :json_library, Poison

# Configure Swoosh with Mailgun
config :efl, Efl.Mailer,
  adapter: Swoosh.Adapters.Mailgun,
  api_key: System.get_env("MAILGUN_API_KEY") || Application.get_env(:mailgun, :mailgun_key),
  domain: System.get_env("MAILGUN_DOMAIN") || Application.get_env(:mailgun, :mailgun_domain)

config :swoosh, :api_client, Swoosh.ApiClient.Hackney
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
