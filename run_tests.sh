#!/bin/bash

# EFL Test Runner - Optimized for Development
# Uses proper MIX_ENV=test and handles test database setup

echo "🧪 EFL Test Runner"
echo "=================="

# Ensure Docker is running before proceeding
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Resolve MySQL host (in case "mysql" DNS fails in container)
get_mysql_host() {
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' efl-mysql 2>/dev/null || echo "mysql"
}

# Ensure app and MySQL containers are up
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

# Function to setup test database and test deps
setup_test_db() {
    local db_host
    db_host=$(get_mysql_host)
    echo "📦 Ensuring test dependencies (mock, etc.)..."
    docker-compose exec -T -e MIX_ENV=test -e TEST_DB_HOST="${db_host}" app mix deps.get >/dev/null 2>&1
    echo "🗄️  Setting up test database..."
    docker-compose exec -T mysql mysql -u root -ppassword -e "CREATE DATABASE IF NOT EXISTS classification_utility_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
    docker-compose exec -T -e MIX_ENV=test -e TEST_DB_HOST="${db_host}" app mix ecto.create --quiet 2>/dev/null || true
    docker-compose exec -T -e MIX_ENV=test -e TEST_DB_HOST="${db_host}" app mix ecto.migrate >/dev/null 2>&1
}

# Function to run tests (exec into running app container)
run_tests() {
    local test_args="$1"
    local db_host
    db_host=$(get_mysql_host)
    echo "📋 Running tests with MIX_ENV=test (DB host: ${db_host})..."
    echo "-----------------------------------"
    local log_file
    log_file=$(mktemp)
    trap "rm -f ${log_file}" EXIT
    docker-compose exec -T -e MIX_ENV=test -e TEST_DB_HOST="${db_host}" app mix test $test_args 2>&1 | tee "${log_file}"
    local exit_code=${PIPESTATUS[0]}
    echo ""
    echo "============== TEST SUMMARY =============="
    tail -20 "${log_file}"
    echo "=========================================="
    return $exit_code
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
test_exit=$?

echo ""
if [ $test_exit -eq 0 ]; then
    echo "✅ All tests passed!"
else
    echo "❌ Some tests failed (exit code $test_exit)"
fi
echo ""
echo "💡 Usage Examples:"
echo "  ./run_tests.sh                           # Run all tests"
echo "  ./run_tests.sh test/models/dadi_test.exs # Run specific test file"
echo "  ./run_tests.sh --max-failures=5         # Run with failure limit"
echo "  ./run_tests.sh test/models/ --trace     # Run with trace output"
exit $test_exit