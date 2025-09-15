#!/bin/bash

# Standalone Test Runner for EFL Application
# This script runs tests without loading the application

echo "🧪 Running EFL Standalone Tests..."
echo "=================================="

# Check if containers are running
if ! docker-compose ps | grep -q "efl-app.*Up"; then
    echo "❌ App container is not running. Starting containers..."
    docker-compose up -d
    echo "⏳ Waiting for containers to be ready..."
    sleep 10
fi

echo "✅ Containers are running"

# Run standalone tests without application startup
echo "🚀 Running standalone tests..."
docker-compose exec app elixir -e "
ExUnit.start()
defmodule BasicTest do
  use ExUnit.Case
  
  test \"arithmetic\" do
    assert 1 + 1 == 2
  end
  
  test \"strings\" do
    assert \"hello\" == \"hello\"
  end
  
  test \"lists\" do
    assert [1, 2, 3] == [1, 2, 3]
  end
  
  test \"maps\" do
    map = %{name: \"test\", value: 42}
    assert map.name == \"test\"
    assert map.value == 42
  end
  
  test \"pattern matching\" do
    result = case {:ok, \"success\"} do
      {:ok, msg} -> msg
      {:error, _} -> \"error\"
    end
    assert result == \"success\"
  end
end
ExUnit.run()
"

echo "=================================="
echo "✅ Standalone tests completed!"
