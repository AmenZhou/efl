use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :efl, Efl.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Allow tests to override strict date validation (default: false in test)
config :efl, :strict_post_date_validation, false

# Don't run real DADI pipeline in controller tests (avoids HTTP/DB and hanging)
config :efl, :dadi_run_main_in_start, false

# Configure your database (hostname: "mysql" for compose; override with TEST_DB_HOST if DNS fails)
config :efl, Efl.Repo,
  adapter: Ecto.Adapters.MyXQL,
  username: "root",
  password: "password",
  database: "classification_utility_test",
  hostname: System.get_env("TEST_DB_HOST") || "mysql",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  queue_target: 5000,
  queue_interval: 1000,
  charset: "utf8mb4",
  collation: "utf8mb4_unicode_ci"
