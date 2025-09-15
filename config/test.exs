use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :efl, Efl.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :efl, Efl.Repo,
  adapter: Ecto.Adapters.MyXQL,
  username: "root",
  password: "password",
  database: "classification_utility_test",
  hostname: "mysql",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1,
  queue_target: 1000,
  queue_interval: 1000,
  charset: "utf8mb4",
  collation: "utf8mb4_unicode_ci"
