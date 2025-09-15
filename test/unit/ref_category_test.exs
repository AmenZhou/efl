defmodule Efl.RefCategoryUnitTest do
  use ExUnit.Case, async: true

  alias Efl.RefCategory

  describe "changeset/2" do
    test "valid changeset with all fields" do
      attrs = %{
        name: "TEST_CATEGORY",
        display_name: "Test Category",
        url: "/test.page",
        page_size: 2
      }
      
      changeset = RefCategory.changeset(%RefCategory{}, attrs)
      
      assert changeset.valid?
      assert changeset.changes.name == "TEST_CATEGORY"
      assert changeset.changes.display_name == "Test Category"
      assert changeset.changes.url == "/test.page"
      assert changeset.changes.page_size == 2
    end

    test "valid changeset with minimal fields" do
      minimal_attrs = %{
        name: "MINIMAL",
        display_name: "Minimal Category"
      }
      
      changeset = RefCategory.changeset(%RefCategory{}, minimal_attrs)
      assert changeset.valid?
    end
  end

  describe "get_urls/1" do
    test "generates correct URLs for category with page_size 2" do
      category = %RefCategory{
        name: "TEST_CATEGORY",
        url: "/test.page",
        page_size: 2
      }
      
      urls = RefCategory.get_urls(category)
      
      assert length(urls) == 2
      assert Enum.at(urls, 0) == "http://c.dadi360.com/c/forums/show/0/test.page"
      assert Enum.at(urls, 1) == "http://c.dadi360.com/c/forums/show/80/test.page"
    end

    test "generates correct URLs for category with page_size 1" do
      category = %RefCategory{
        name: "SINGLE_PAGE",
        url: "/single.page",
        page_size: 1
      }
      
      urls = RefCategory.get_urls(category)
      
      assert length(urls) == 1
      assert Enum.at(urls, 0) == "http://c.dadi360.com/c/forums/show/0/single.page"
    end

    test "handles category without page_size (defaults to 1)" do
      category = %RefCategory{
        name: "NO_PAGE_SIZE",
        url: "/no_size.page"
      }
      
      urls = RefCategory.get_urls(category)
      
      assert length(urls) == 1
      assert Enum.at(urls, 0) == "http://c.dadi360.com/c/forums/show/0/no_size.page"
    end

    test "generates correct URLs for category with page_size 3" do
      category = %RefCategory{
        name: "MULTI_PAGE",
        url: "/multi.page",
        page_size: 3
      }
      
      urls = RefCategory.get_urls(category)
      
      assert length(urls) == 3
      assert Enum.at(urls, 0) == "http://c.dadi360.com/c/forums/show/0/multi.page"
      assert Enum.at(urls, 1) == "http://c.dadi360.com/c/forums/show/80/multi.page"
      assert Enum.at(urls, 2) == "http://c.dadi360.com/c/forums/show/160/multi.page"
    end
  end

  describe "ref_data constant" do
    test "contains expected categories" do
      # Test that the @ref_data constant contains the expected structure
      ref_data = Efl.RefCategory.__info__(:constants)[:ref_data]
      
      assert is_list(ref_data)
      assert length(ref_data) == 16
      
      # Check specific categories exist
      category_names = ref_data |> Enum.map(& &1.name) |> MapSet.new()
      assert MapSet.member?(category_names, "FLUSHING_HOUSE_RENT")
      assert MapSet.member?(category_names, "QUEENS_HOUSE_RENT")
      assert MapSet.member?(category_names, "NAIL_HIRING")
      assert MapSet.member?(category_names, "RESTAURANT_HIRING")
    end

    test "all categories have required fields" do
      ref_data = Efl.RefCategory.__info__(:constants)[:ref_data]
      
      for category <- ref_data do
        assert Map.has_key?(category, :name)
        assert Map.has_key?(category, :display_name)
        assert Map.has_key?(category, :url)
        assert Map.has_key?(category, :page_size)
        
        assert is_binary(category.name)
        assert is_binary(category.display_name)
        assert is_binary(category.url)
        assert is_integer(category.page_size)
        assert category.page_size > 0
      end
    end
  end
end
