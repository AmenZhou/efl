#!/bin/bash

# Fast test runner - no Docker rebuild needed
# This script runs tests using volume-mounted code

echo "🚀 Running Fast Tests (No Rebuild Required)"
echo "=========================================="

# Check if containers are running
if ! docker-compose ps | grep -q "efl-app.*Up"; then
    echo "❌ App container is not running. Starting containers..."
    docker-compose up -d
    sleep 10
fi

echo "📋 Running Tests..."
echo "-------------------"

# Run tests directly in the running container (single-threaded to avoid DB connection issues)
docker-compose exec -e MIX_ENV=test app mix test --max-cases 1

echo ""
echo "✅ Tests completed!"
echo ""
echo "💡 Tips:"
echo "  - Code changes are reflected immediately (no rebuild needed)"
echo "  - Use 'docker-compose exec app mix test test/specific_file.exs' for specific tests"
echo "  - Use 'docker-compose exec app iex -S mix' for interactive development"
