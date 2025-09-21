#!/bin/bash

# EFL Test Runner - Optimized for Development
# Uses proper MIX_ENV=test and handles test database setup

echo "🧪 EFL Test Runner"
echo "=================="

# Function to check container status
check_containers() {
    if ! docker-compose ps | grep -q "efl-app.*Up"; then
        echo "❌ App container not running. Starting containers..."
        docker-compose up -d
        echo "⏳ Waiting for containers to initialize..."
        sleep 15
    fi

    if ! docker-compose ps | grep -q "efl-mysql.*healthy"; then
        echo "⏳ Waiting for MySQL to be healthy..."
        sleep 10
    fi
}

# Function to setup test database
setup_test_db() {
    echo "🗄️  Setting up test database..."
    docker-compose exec -T mysql mysql -u root -ppassword -e "CREATE DATABASE IF NOT EXISTS classification_utility_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
    docker-compose exec -T -e MIX_ENV=test app mix ecto.migrate >/dev/null 2>&1
}

# Function to run tests
run_tests() {
    local test_args="$1"
    echo "📋 Running tests with MIX_ENV=test..."
    echo "-----------------------------------"
    docker-compose exec -e MIX_ENV=test app mix test $test_args
}

# Main execution
check_containers
setup_test_db

# Check if specific test file or options were provided
if [ $# -eq 0 ]; then
    echo "🚀 Running all tests..."
    run_tests "--max-cases 1"
else
    echo "🎯 Running specific tests: $*"
    run_tests "$*"
fi

echo ""
echo "✅ Test execution completed!"
echo ""
echo "💡 Usage Examples:"
echo "  ./run_tests.sh                           # Run all tests"
echo "  ./run_tests.sh test/models/dadi_test.exs # Run specific test file"
echo "  ./run_tests.sh --max-failures=5         # Run with failure limit"
echo "  ./run_tests.sh test/models/ --trace     # Run with trace output"