#!/bin/bash

# Production Deployment Script for EFL Application (with Docker caching)

set -e

echo "🚀 Starting EFL Production Deployment (with Docker caching)..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Load environment variables
if [ -f "env.prod" ]; then
    echo "📋 Loading environment variables..."
    export $(cat env.prod | grep -v '^#' | xargs)
fi

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose -f docker-compose.prod.yml down || true

# Build the application using cached layers
echo "🔨 Building Elixir application (with caching)..."
echo "   This will be much faster on subsequent builds!"
docker-compose -f docker-compose.prod.yml build --no-cache efl-app

# Start MySQL first
echo "🗄️ Starting MySQL database..."
docker-compose -f docker-compose.prod.yml up -d mysql

# Wait for MySQL to be ready
echo "⏳ Waiting for MySQL to be ready..."
sleep 30

# Run database migrations
echo "📊 Running database migrations..."
docker-compose -f docker-compose.prod.yml run --rm efl-app mix ecto.migrate

# Start the application
echo "🚀 Starting EFL application..."
docker-compose -f docker-compose.prod.yml up -d efl-app

# Start phpMyAdmin (optional)
echo "🔧 Starting phpMyAdmin..."
docker-compose -f docker-compose.prod.yml up -d phpmyadmin

echo "✅ Deployment completed!"
echo "🌐 Application is running at: http://localhost:4000"
echo "🔧 phpMyAdmin is available at: http://localhost:8080"
echo ""
echo "📋 Useful commands:"
echo "  View logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "  Stop all: docker-compose -f docker-compose.prod.yml down"
echo "  Restart app: docker-compose -f docker-compose.prod.yml restart efl-app"
echo "  Rebuild with cache: docker-compose -f docker-compose.prod.yml build efl-app"
echo ""
echo "💡 Caching benefits:"
echo "  - Dependencies are cached in volumes"
echo "  - Compiled files are cached"
echo "  - Subsequent builds are much faster"
echo "  - Only source code changes trigger recompilation"


