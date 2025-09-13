#!/bin/bash

# Production Deployment Script for EFL Application (Multi-stage Docker)

set -e

echo "🚀 Starting EFL Production Deployment (Multi-stage Docker)..."

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

# Clean up old images to free space
echo "🧹 Cleaning up old Docker images..."
docker system prune -f

# Build the application using multi-stage build
echo "🔨 Building Elixir application (multi-stage)..."
echo "   This will be faster than the previous build!"
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
echo ""
echo "💡 Multi-stage build benefits:"
echo "  - Faster compilation (build stage isolated)"
echo "  - Smaller runtime image"
echo "  - Better security (minimal runtime dependencies)"