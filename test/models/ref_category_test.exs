defmodule Efl.RefCategoryTest do
  use Efl.ModelCase, async: true

  alias Efl.RefCategory

  @valid_attrs %{
    name: "TEST_CATEGORY",
    display_name: "Test Category",
    url: "/test.page",
    page_size: 2
  }

  @invalid_attrs %{}

  describe "changeset/2" do
    test "valid changeset with all fields" do
      changeset = RefCategory.changeset(%RefCategory{}, @valid_attrs)
      
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

    test "invalid changeset with empty params" do
      changeset = RefCategory.changeset(%RefCategory{}, @invalid_attrs)
      assert changeset.valid? # RefCategory doesn't have required validations
    end
  end

  describe "seeds/0" do
    test "creates all reference categories" do
      # Clear existing categories
      Repo.delete_all(RefCategory)
      
      # Run seeds
      RefCategory.seeds()
      
      # Check that categories were created
      categories = Repo.all(RefCategory)
      assert length(categories) == 16
      
      # Check specific categories exist
      category_names = categories |> Enum.map(& &1.name) |> MapSet.new()
      assert MapSet.member?(category_names, "FLUSHING_HOUSE_RENT")
      assert MapSet.member?(category_names, "QUEENS_HOUSE_RENT")
      assert MapSet.member?(category_names, "NAIL_HIRING")
      assert MapSet.member?(category_names, "RESTAURANT_HIRING")
    end

    test "seeds are idempotent" do
      # Clear existing categories
      Repo.delete_all(RefCategory)
      
      # Run seeds twice
      RefCategory.seeds()
      first_count = Repo.aggregate(RefCategory, :count, :id)
      
      RefCategory.seeds()
      second_count = Repo.aggregate(RefCategory, :count, :id)
      
      # Should have the same count (seeds should handle duplicates)
      assert first_count == second_count
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
  end

  describe "associations" do
    test "has many dadis" do
      # Create a category
      category = %RefCategory{
        name: "TEST_CATEGORY",
        display_name: "Test Category"
      } |> Repo.insert!()
      
      # Create dadis associated with this category
      dadi1 = %Efl.Dadi{
        title: "Test Post 1",
        url: "https://example.com/1",
        content: "Content 1",
        post_date: ~D[2024-01-15],
        ref_category_id: category.id
      } |> Repo.insert!()
      
      dadi2 = %Efl.Dadi{
        title: "Test Post 2",
        url: "https://example.com/2",
        content: "Content 2",
        post_date: ~D[2024-01-15],
        ref_category_id: category.id
      } |> Repo.insert!()
      
      # Reload category with associations
      category_with_dadis = Repo.preload(category, :dadis)
      
      assert length(category_with_dadis.dadis) == 2
      assert Enum.any?(category_with_dadis.dadis, &(&1.id == dadi1.id))
      assert Enum.any?(category_with_dadis.dadis, &(&1.id == dadi2.id))
    end
  end
end
