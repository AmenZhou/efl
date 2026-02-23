import Config

# Import development HTTP configuration
import_config "dev_http.exs"

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :efl, Efl.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
                    cd: Path.expand("../", __DIR__)]]


# Watch static and templates for browser reloading.
config :efl, Efl.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database (DB_HOST from env when "mysql" doesn't resolve, e.g. custom network)
config :efl, Efl.Repo,
  adapter: Ecto.Adapters.MyXQL,
  username: "root",
  password: "password",
  database: "classification_utility_dev",
  hostname: System.get_env("DB_HOST") || "mysql",
  pool_size: 20,
  charset: "utf8mb4",
  collation: "utf8mb4_unicode_ci"

import_config "proxy_rotator.exs"
import_config "mailgun.exs"
