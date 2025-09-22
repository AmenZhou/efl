# Single-stage lightweight image - no precompilation
FROM elixir:1.17-alpine

# Install runtime dependencies
RUN apk add --no-cache \
    build-base \
    git \
    mysql-client \
    openssl \
    ncurses-libs \
    wget \
    curl \
    ca-certificates \
    libssl1.1

# Create non-root user
RUN addgroup -g 1000 -S app && \
    adduser -u 1000 -S app -G app

# Set working directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy ALL source code first (better for caching and dependency resolution)
COPY . .

# Install dependencies as root (ensures proper permissions and access to all files)
RUN mix deps.get

# Compile dependencies as root to ensure they're available
RUN mix deps.compile

# Change ownership of everything to app user
RUN chown -R app:app /app

# Ensure the app user has access to mix cache
RUN mkdir -p /home/app/.mix && chown -R app:app /home/app

# Switch to non-root user
USER app

# Expose port
EXPOSE 4000

# Set environment
ENV MIX_ENV=dev
ENV PORT=4000
ENV MIX_HOME=/home/app/.mix

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:4000/ || exit 1

# Start the application (compiles at runtime)
CMD ["sh", "-c", "mix deps.get && mix compile && mix phx.server"]