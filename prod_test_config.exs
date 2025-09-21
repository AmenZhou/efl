# Production Test Configuration
# This file contains configuration overrides for production testing

# Override email settings for testing
config :efl, Efl.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: "localhost",
  port: 1025,
  tls: :never,
  auth: :never

# Test email recipients
config :efl, :test_email,
  recipient: "test@example.com",
  from: "EFL Test System <noreply@efl.local>"

# Override database settings for testing
config :efl, Efl.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5

# Test logging level
config :logger, level: :info

# Test environment specific settings
config :efl, :test_mode, true

# Performance test settings
config :efl, :performance_test,
  max_html_size: 1_000_000,  # 1MB
  max_processing_time: 30_000,  # 30 seconds
  max_memory_usage: 100_000_000  # 100MB

# Security test settings
config :efl, :security_test,
  max_title_length: 1000,
  max_url_length: 2000,
  max_content_length: 50_000,
  allowed_date_range: 365  # days

# Excel generation test settings
config :efl, :excel_test,
  min_file_size: 1000,  # bytes
  max_file_size: 10_000_000,  # 10MB
  test_filename: "EFL_Test_Export"

# Email test settings
config :efl, :email_test,
  test_subject_prefix: "[TEST]",
  test_recipient: "test@example.com",
  test_from: "EFL Test System <noreply@efl.local>",
  max_attachment_size: 25_000_000  # 25MB

IO.puts "Production test configuration loaded successfully"
IO.puts "Configuration includes:"
IO.puts "  - Email testing settings"
IO.puts "  - Database testing configuration"
IO.puts "  - Performance test limits"
IO.puts "  - Security test parameters"
IO.puts "  - Excel generation test settings"

