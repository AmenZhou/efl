#!/bin/bash

# Development Deployment Script for EFL Application (with Docker caching)

set -e

echo "🚀 Starting EFL Development Environment (with Docker caching)..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Load environment variables
if [ -f "env.dev" ]; then
    echo "📋 Loading environment variables..."
    export $(cat env.dev | grep -v '^#' | xargs)
else
    echo "📋 Using default development environment variables..."
    export MYSQL_ROOT_PASSWORD=password
    export MYSQL_DATABASE=classification_utility_dev
    export MYSQL_USER=hzhou
    export MYSQL_PASSWORD=password123
    export SECRET_KEY_BASE=dev-secret-key
fi

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose -f docker-compose.dev.yml down || true

# Build the application using cached layers
echo "🔨 Building Elixir application (with caching)..."
echo "   This will be much faster on subsequent builds!"
docker-compose -f docker-compose.dev.yml build efl-app

# Start MySQL first
echo "🗄️ Starting MySQL database..."
docker-compose -f docker-compose.dev.yml up -d mysql

# Wait for MySQL to be ready
echo "⏳ Waiting for MySQL to be ready..."
sleep 30

# Run database migrations
echo "📊 Running database migrations..."
docker-compose -f docker-compose.dev.yml run --rm efl-app mix ecto.migrate

# Start the application
echo "🚀 Starting EFL application (development mode)..."
docker-compose -f docker-compose.dev.yml up -d efl-app

# Start phpMyAdmin (optional)
echo "🔧 Starting phpMyAdmin..."
docker-compose -f docker-compose.dev.yml up -d phpmyadmin

echo "✅ Development environment started!"
echo "🌐 Application is running at: http://localhost:4000"
echo "🔧 phpMyAdmin is available at: http://localhost:8080"
echo ""
echo "📋 Useful commands:"
echo "  View logs: docker-compose -f docker-compose.dev.yml logs -f"
echo "  Stop all: docker-compose -f docker-compose.dev.yml down"
echo "  Restart app: docker-compose -f docker-compose.dev.yml restart efl-app"
echo "  Rebuild with cache: docker-compose -f docker-compose.dev.yml build efl-app"
echo "  Shell into container: docker-compose -f docker-compose.dev.yml exec efl-app bash"
echo ""
echo "💡 Development features:"
echo "  - Live code reloading"
echo "  - Cached dependencies and compiled files"
echo "  - Source code mounted for instant changes"
echo "  - Fast rebuilds on code changes"


