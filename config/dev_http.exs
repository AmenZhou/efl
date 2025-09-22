# Development HTTP configuration
# This file provides development-specific HTTP client configuration
# that bypasses proxy requirements for local testing.

import Config

# Configure HTTP clients for development
config :efl, :http_client, Efl.DevMyHttp

# Disable proxy rotation in development
config :proxy_rotator, :enabled, false

# Configure development-specific timeouts
config :efl, :http_timeout, 30_000
config :efl, :max_retries, 5

# Development logging configuration
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :url, :method]

# Disable external service calls in development if needed
config :efl, :external_services_enabled, true
