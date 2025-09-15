defmodule SimpleTest do
  use ExUnit.Case, async: true

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

  test "module compilation works" do
    # Test that our modules can be compiled
    assert Code.ensure_loaded?(Efl.Dadi)
    assert Code.ensure_loaded?(Efl.RefCategory)
    assert Code.ensure_loaded?(Efl.Mailer)
  end

  test "module functions exist" do
    # Test that expected functions exist
    assert function_exported?(Efl.Dadi, :changeset, 2)
    assert function_exported?(Efl.Dadi, :update_changeset, 2)
    assert function_exported?(Efl.RefCategory, :changeset, 2)
    assert function_exported?(Efl.RefCategory, :get_urls, 1)
    assert function_exported?(Efl.Mailer, :send_email_with_xls, 0)
  end

  test "changeset validation works" do
    # Test changeset without database
    changeset = Efl.Dadi.changeset(%Efl.Dadi{}, %{})
    
    refute changeset.valid?
    assert changeset.errors[:title] == {"can't be blank", [validation: :required]}
    assert changeset.errors[:url] == {"can't be blank", [validation: :required]}
  end

  test "ref category URL generation works" do
    category = %Efl.RefCategory{
      name: "TEST",
      url: "/test.page",
      page_size: 2
    }
    
    urls = Efl.RefCategory.get_urls(category)
    
    assert length(urls) == 2
    assert Enum.at(urls, 0) == "http://c.dadi360.com/c/forums/show/0/test.page"
    assert Enum.at(urls, 1) == "http://c.dadi360.com/c/forums/show/80/test.page"
  end
end
