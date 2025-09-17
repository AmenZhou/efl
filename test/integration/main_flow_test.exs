defmodule Efl.MainFlowTest do
  use Efl.ConnCase, async: false

  alias Efl.Dadi
  alias Efl.RefCategory

  setup do
    # Clear all data before each test
    Repo.delete_all(Dadi)
    Repo.delete_all(RefCategory)
    
    {:ok, %{}}
  end

  describe "Complete Main Flow" do
    test "homepage displays posts when data exists" do
      # Create test data
      ref_category = %RefCategory{
        name: "TEST_CATEGORY",
        display_name: "Test Category",
        page_size: 1
      } |> Repo.insert!()

      dadi_post = %Dadi{
        title: "Test Apartment for Rent",
        url: "https://example.com/rental/123",
        content: "Beautiful 2BR apartment in Flushing",
        phone: "555-123-4567",
        post_date: ~D[2024-01-15],
        ref_category_id: ref_category.id
      } |> Repo.insert!()

      # Visit homepage
      conn = get(build_conn(), "/")
      
      # Assertions
      assert html_response(conn, 200)
      assert conn.resp_body =~ "Test Apartment for Rent"
      assert conn.resp_body =~ "Beautiful 2BR apartment in Flushing"
      assert conn.resp_body =~ "555-123-4567"
    end

    test "homepage shows empty state when no data exists" do
      conn = get(build_conn(), "/")
      
      assert html_response(conn, 200)
      # The page should still load even with no data
    end

    test "scratch endpoint requires localhost access" do
      # Test with non-localhost IP
      conn = %{build_conn() | remote_ip: {192, 168, 1, 100}}
      conn = get(conn, "/dadi/scratch")
      
      assert text_response(conn, 200) =~ "No permission"
    end

    test "scratch endpoint allows localhost access" do
      # Test with localhost IP
      conn = %{build_conn() | remote_ip: {127, 0, 0, 1}}
      conn = get(conn, "/dadi/scratch")
      
      assert text_response(conn, 200) =~ "Start scratching DD360..."
    end
  end

  describe "Data Model Relationships" do
    test "dadi belongs to ref_category" do
      # Create category
      category = %RefCategory{
        name: "HOUSE_RENT",
        display_name: "House Rental",
        page_size: 2
      } |> Repo.insert!()

      # Create dadi post
      dadi = %Dadi{
        title: "2BR Apartment",
        url: "https://example.com/apt",
        content: "Nice apartment",
        post_date: ~D[2024-01-15],
        ref_category_id: category.id
      } |> Repo.insert!()

      # Test association
      dadi_with_category = Repo.preload(dadi, :ref_category)
      assert dadi_with_category.ref_category.id == category.id
      assert dadi_with_category.ref_category.name == "HOUSE_RENT"
    end

    test "ref_category has many dadis" do
      # Create category
      category = %RefCategory{
        name: "JOBS",
        display_name: "Job Listings",
        page_size: 3
      } |> Repo.insert!()

      # Create multiple dadi posts
      dadi1 = %Dadi{
        title: "Restaurant Job",
        url: "https://example.com/job1",
        content: "Server position",
        post_date: ~D[2024-01-15],
        ref_category_id: category.id
      } |> Repo.insert!()

      dadi2 = %Dadi{
        title: "Office Job",
        url: "https://example.com/job2",
        content: "Admin position",
        post_date: ~D[2024-01-15],
        ref_category_id: category.id
      } |> Repo.insert!()

      # Test association
      category_with_dadis = Repo.preload(category, :dadis)
      assert length(category_with_dadis.dadis) == 2
      
      dadi_titles = category_with_dadis.dadis |> Enum.map(& &1.title)
      assert "Restaurant Job" in dadi_titles
      assert "Office Job" in dadi_titles
    end
  end

  describe "Data Validation" do
    test "dadi requires unique URLs" do
      category = %RefCategory{
        name: "TEST",
        display_name: "Test Category"
      } |> Repo.insert!()

      # Create first post
      dadi1 = %Dadi{
        title: "First Post",
        url: "https://example.com/unique",
        content: "Content 1",
        post_date: ~D[2024-01-15],
        ref_category_id: category.id
      } |> Repo.insert!()

      # Try to create duplicate URL - should fail at database level
      changeset = Dadi.changeset(%Dadi{}, %{
        title: "Second Post",
        url: "https://example.com/unique", # Same URL
        content: "Content 2",
        post_date: ~D[2024-01-15],
        ref_category_id: category.id
      })

      # The changeset is valid, but database insert should fail
      assert changeset.valid?
      
      # Database insert should fail with constraint error
      assert {:error, changeset} = Repo.insert(changeset)
      refute changeset.valid?
      assert changeset.errors[:url] == {"has already been taken", [constraint: :unique, constraint_name: "dadi_url_index"]}
    end

    test "dadi validates required fields" do
      changeset = Dadi.changeset(%Dadi{}, %{})
      
      refute changeset.valid?
      assert changeset.errors[:title] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:url] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:post_date] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:ref_category_id] == {"can't be blank", [validation: :required]}
    end
  end

  describe "RefCategory URL Generation" do
    test "generates correct URLs for different page sizes" do
      # Test category with multiple pages
      multi_page_category = %RefCategory{
        name: "MULTI_PAGE",
        display_name: "Multi Page Category",
        url: "/multi.page",
        page_size: 3
      }

      urls = RefCategory.get_urls(multi_page_category)
      
      assert length(urls) == 3
      assert Enum.at(urls, 0) == "http://c.dadi360.com/c/forums/show/0/multi.page"
      assert Enum.at(urls, 1) == "http://c.dadi360.com/c/forums/show/80/multi.page"
      assert Enum.at(urls, 2) == "http://c.dadi360.com/c/forums/show/160/multi.page"
    end

    test "seeds create all expected categories" do
      # Run seeds
      RefCategory.seeds()
      
      # Verify all categories were created
      categories = Repo.all(RefCategory)
      assert length(categories) == 16
      
      # Check specific categories
      category_map = categories |> Enum.into(%{}, & {&1.name, &1})
      
      assert category_map["FLUSHING_HOUSE_RENT"].display_name == "法拉盛租房"
      assert category_map["QUEENS_HOUSE_RENT"].display_name == "皇后区租房"
      assert category_map["NAIL_HIRING"].display_name == "美甲招人"
      assert category_map["RESTAURANT_HIRING"].display_name == "餐馆招人"
    end
  end
end
