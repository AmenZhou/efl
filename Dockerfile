# Multi-stage Docker build with caching for EFL Elixir application

# Stage 1: Dependencies stage
FROM elixir:1.17.3-otp-26 AS deps

# Install system dependencies for building
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix files first (for better Docker layer caching)
COPY mix.exs mix.lock ./

# Install dependencies
RUN mix deps.get --only prod

# Stage 2: Build stage
FROM deps AS builder

# Copy source code
COPY . .

# Compile the application
RUN MIX_ENV=prod mix compile

# Stage 3: Runtime stage
FROM elixir:1.17.3-otp-26 AS runtime

# Install only runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create app user for security
RUN groupadd -r app && useradd -r -g app app

# Set working directory
WORKDIR /app

# Copy compiled application from builder stage
COPY --from=builder /app/_build ./_build
COPY --from=builder /app/priv ./priv
COPY --from=builder /app/config ./config
COPY --from=builder /app/mix.exs ./mix.exs
COPY --from=builder /app/mix.lock ./mix.lock
COPY --from=builder /app/lib ./lib
COPY --from=builder /app/web ./web

# Create necessary directories
RUN mkdir -p /app/logs && \
    chown -R app:app /app

# Switch to app user
USER app

# Expose port
EXPOSE 4000

# Set environment
ENV MIX_ENV=prod
ENV PORT=4000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:4000/ || exit 1

# Start the application
CMD ["mix", "phx.server"]