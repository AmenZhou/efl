# Email Test Configuration
# This file can be used to override email settings for testing

# Uncomment and modify these settings for your email testing:

# For Gmail SMTP testing:
# config :swoosh,
#   api_client: Swoosh.ApiClient.Hackney,
#   adapter: Swoosh.Adapters.SMTP,
#   relay: "smtp.gmail.com",
#   port: 587,
#   username: "your-email@gmail.com",
#   password: "your-app-password",
#   tls: :always,
#   auth: :always

# For Mailgun testing:
# config :swoosh,
#   api_client: Swoosh.ApiClient.Hackney,
#   adapter: Swoosh.Adapters.Mailgun,
#   api_key: "your-mailgun-api-key",
#   domain: "your-mailgun-domain"

# For local testing with MailHog (https://github.com/mailhog/MailHog):
# config :swoosh,
#   api_client: Swoosh.ApiClient.Hackney,
#   adapter: Swoosh.Adapters.SMTP,
#   relay: "localhost",
#   port: 1025,
#   tls: :never,
#   auth: :never

# Test recipient configuration
# config :efl, :test_email,
#   recipient: "your-test-email@example.com",
#   from: "EFL Test System <noreply@efl.local>"

IO.puts "Email test configuration loaded."
IO.puts "To use this configuration, run:"
IO.puts "  docker-compose exec app mix run -c test_email_config.exs test_prod_email.exs"
