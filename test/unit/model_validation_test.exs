defmodule ModelValidationTest do
  use ExUnit.Case, async: true

  # Test model changesets without database
  test "Dadi changeset validation works" do
    # Test valid changeset
    valid_attrs = %{
      title: "Test Post",
      url: "https://example.com/test",
      content: "Test content",
      phone: "123-456-7890",
      post_date: ~D[2024-01-15],
      ref_category_id: 1
    }
    
    changeset = Efl.Dadi.changeset(%Efl.Dadi{}, valid_attrs)
    assert changeset.valid?
    assert changeset.changes.title == "Test Post"
    assert changeset.changes.url == "https://example.com/test"
  end

  test "Dadi changeset validation fails for missing required fields" do
    changeset = Efl.Dadi.changeset(%Efl.Dadi{}, %{})
    
    refute changeset.valid?
    assert changeset.errors[:title] == {"can't be blank", [validation: :required]}
    assert changeset.errors[:url] == {"can't be blank", [validation: :required]}
    assert changeset.errors[:post_date] == {"can't be blank", [validation: :required]}
    assert changeset.errors[:ref_category_id] == {"can't be blank", [validation: :required]}
  end

  test "RefCategory changeset validation works" do
    valid_attrs = %{
      name: "TEST_CATEGORY",
      display_name: "Test Category",
      url: "/test.page",
      page_size: 2
    }
    
    changeset = Efl.RefCategory.changeset(%Efl.RefCategory{}, valid_attrs)
    assert changeset.valid?
    assert changeset.changes.name == "TEST_CATEGORY"
    assert changeset.changes.display_name == "Test Category"
  end

  test "RefCategory URL generation works" do
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

  test "RefCategory URL generation works for single page" do
    category = %Efl.RefCategory{
      name: "SINGLE",
      url: "/single.page",
      page_size: 1
    }
    
    urls = Efl.RefCategory.get_urls(category)
    
    assert length(urls) == 1
    assert Enum.at(urls, 0) == "http://c.dadi360.com/c/forums/show/0/single.page"
  end

  test "RefCategory URL generation works for multiple pages" do
    category = %Efl.RefCategory{
      name: "MULTI",
      url: "/multi.page",
      page_size: 3
    }
    
    urls = Efl.RefCategory.get_urls(category)
    
    assert length(urls) == 3
    assert Enum.at(urls, 0) == "http://c.dadi360.com/c/forums/show/0/multi.page"
    assert Enum.at(urls, 1) == "http://c.dadi360.com/c/forums/show/80/multi.page"
    assert Enum.at(urls, 2) == "http://c.dadi360.com/c/forums/show/160/multi.page"
  end

  test "RefCategory URL generation handles missing page_size" do
    category = %Efl.RefCategory{
      name: "NO_SIZE",
      url: "/no_size.page"
    }
    
    urls = Efl.RefCategory.get_urls(category)
    
    assert length(urls) == 1
    assert Enum.at(urls, 0) == "http://c.dadi360.com/c/forums/show/0/no_size.page"
  end
end
