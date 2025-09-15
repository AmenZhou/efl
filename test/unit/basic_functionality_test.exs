defmodule BasicFunctionalityTest do
  use ExUnit.Case, async: true

  # Test basic Elixir functionality
  test "basic arithmetic works" do
    assert 1 + 1 == 2
    assert 2 * 3 == 6
    assert 10 / 2 == 5.0
  end

  test "string operations work" do
    assert "hello" <> " " <> "world" == "hello world"
    assert String.length("test") == 4
    assert String.upcase("hello") == "HELLO"
  end

  test "list operations work" do
    list = [1, 2, 3, 4, 5]
    assert length(list) == 5
    assert Enum.sum(list) == 15
    assert Enum.map(list, &(&1 * 2)) == [2, 4, 6, 8, 10]
  end

  test "map operations work" do
    map = %{name: "test", value: 42}
    assert map.name == "test"
    assert map.value == 42
    assert Map.has_key?(map, :name)
    assert Map.keys(map) == [:name, :value]
  end

  test "pattern matching works" do
    result = case {:ok, "success"} do
      {:ok, message} -> message
      {:error, _} -> "error"
    end
    assert result == "success"
  end

  test "function definitions work" do
    add = fn a, b -> a + b end
    assert add.(2, 3) == 5
    
    multiply = &(&1 * &2)
    assert multiply.(4, 5) == 20
  end
end
