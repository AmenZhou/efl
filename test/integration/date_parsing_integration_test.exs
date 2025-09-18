defmodule Efl.DateParsingIntegrationTest do
  use Efl.ModelCase, async: false
  alias Efl.HtmlParsers.Dadi.Category
  alias Efl.Dadi
  alias Efl.RefCategory

  setup do
    # Create a test category
    ref_category = %RefCategory{
      name: "test_category",
      display_name: "Test Category",
      page_size: 5
    } |> Repo.insert!()

    {:ok, ref_category: ref_category}
  end

  describe "complete date parsing flow" do
    test "parses HTML, extracts date, and validates correctly", %{ref_category: ref_category} do
      # Test the complete flow from HTML parsing to database validation
      html_with_dates = """
      <tr class="bg_small_yellow">
        <td class="row1Announce" valign="middle" align="center" width="20">
          <img class="icon_folder_announce" src="/c/images/transp.gif" alt="" />
        </td>
        <td class="row1Announce" width="100%">
          <span class="topictitle">
            <a href="/c/posts/list/3942533.page;jsessionid=E114E2AE774EEECE7A80BF5D0C2C0DBC">
              <span class="topictitlehl">
                Elmhurst 新 2 房2衛，1000sqft
              </span>
            </a>
          </span>
        </td>
        <td class="row2Announce" valign="middle" align="center">
          <span class="postdetails">22</span>
        </td>
        <td class="row3" valign="middle" align="center">
          <div style="width:40px; overflow:hidden;white-space: nowrap;text-overflow: ellipsis;">
            <span class="name"><a href="/">user123</a></span>
          </div>
        </td>
        <td class="row2Announce" valign="middle" align="center">
          <span class="postdetails">455634</span>
        </td>
        <td class="row3Announce" valign="middle" nowrap="nowrap" align="center">
          <span class="postdetails">9/16/2025</span>
        </td>
      </tr>
      """

      # Step 1: Parse HTML and extract data
      {:ok, items} = Category.find_raw_items({:ok, html_with_dates})
      assert length(items) >= 1

      first_item = List.first(items)
      
      # Step 2: Extract individual components
      title = Category.get_title(first_item)
      link = Category.get_link(first_item)
      post_date = Category.get_date(first_item)

      # Step 3: Verify extraction worked correctly
      assert title == "Elmhurst 新 2 房2衛，1000sqft"
      assert link == "/c/posts/list/3942533.page"
      assert post_date == ~D[2025-09-16]

      # Step 4: Create Dadi params (simulating what happens in production)
      dadi_params = %{
        title: title,
        url: "http://c.dadi360.com" <> link,
        post_date: post_date,
        ref_category_id: ref_category.id,
        phone: nil,
        content: nil
      }

      # Step 5: Validate with Dadi changeset
      changeset = Dadi.changeset(%Dadi{}, dadi_params)
      assert changeset.valid?, "Changeset should be valid with correctly parsed date"

      # Step 6: Insert into database
      {:ok, dadi} = Repo.insert(changeset)
      assert dadi.title == title
      assert dadi.url == "http://c.dadi360.com" <> link
      assert dadi.post_date == post_date
      assert dadi.ref_category_id == ref_category.id
    end

    test "handles multiple items with different dates correctly", %{ref_category: ref_category} do
      # Test processing multiple items with different date formats
      html_with_multiple_dates = """
      <tr class="bg_small_yellow">
        <td class="topictitle">
          <a href="/c/posts/list/1.page">
            <span class="topictitlehl">Item 1</span>
          </a>
        </td>
        <td class="postdetails">9/16/2025</td>
      </tr>
      <tr class="bg_small_yellow">
        <td class="topictitle">
          <a href="/c/posts/list/2.page">
            <span class="topictitlehl">Item 2</span>
          </a>
        </td>
        <td class="postdetails">8/31/2025</td>
      </tr>
      <tr class="bg_small_yellow">
        <td class="topictitle">
          <a href="/c/posts/list/3.page">
            <span class="topictitlehl">Item 3</span>
          </a>
        </td>
        <td class="postdetails">12/25/2025</td>
      </tr>
      """

      {:ok, items} = Category.find_raw_items({:ok, html_with_multiple_dates})
      assert length(items) >= 3

      expected_dates = [~D[2025-09-16], ~D[2025-08-31], ~D[2025-12-25]]
      expected_titles = ["Item 1", "Item 2", "Item 3"]
      expected_links = ["/c/posts/list/1.page", "/c/posts/list/2.page", "/c/posts/list/3.page"]

      # Process each item
      for {item, expected_title, expected_link, expected_date} <- 
          Enum.zip([items, expected_titles, expected_links, expected_dates]) do
        
        title = Category.get_title(item)
        link = Category.get_link(item)
        post_date = Category.get_date(item)

        assert title == expected_title
        assert link == expected_link
        assert post_date == expected_date

        # Test database insertion
        dadi_params = %{
          title: title,
          url: "http://c.dadi360.com" <> link,
          post_date: post_date,
          ref_category_id: ref_category.id,
          phone: nil,
          content: nil
        }

        changeset = Dadi.changeset(%Dadi{}, dadi_params)
        assert changeset.valid?, "Changeset should be valid for #{title} with date #{post_date}"
      end
    end

    test "handles edge cases in real-world scenarios", %{ref_category: ref_category} do
      # Test edge cases that might occur in production
      edge_case_html = """
      <tr class="bg_small_yellow">
        <td class="topictitle">
          <a href="/c/posts/list/edge1.page">
            <span class="topictitlehl">Edge Case 1: Single digit month</span>
          </a>
        </td>
        <td class="postdetails">1/1/2025</td>
      </tr>
      <tr class="bg_small_yellow">
        <td class="topictitle">
          <a href="/c/posts/list/edge2.page">
            <span class="topictitlehl">Edge Case 2: Zero-padded month</span>
          </a>
        </td>
        <td class="postdetails">01/15/2025</td>
      </tr>
      <tr class="bg_small_yellow">
        <td class="topictitle">
          <a href="/c/posts/list/edge3.page">
            <span class="topictitlehl">Edge Case 3: Invalid date</span>
          </a>
        </td>
        <td class="postdetails">13/32/2025</td>
      </tr>
      <tr class="bg_small_yellow">
        <td class="topictitle">
          <a href="/c/posts/list/edge4.page">
            <span class="topictitlehl">Edge Case 4: Malformed date</span>
          </a>
        </td>
        <td class="postdetails">not-a-date</td>
      </tr>
      """

      {:ok, items} = Category.find_raw_items({:ok, edge_case_html})
      assert length(items) >= 4

      # Test valid dates
      valid_items = Enum.take(items, 2)
      expected_valid_dates = [~D[2025-01-01], ~D[2025-01-15]]

      for {item, expected_date} <- Enum.zip(valid_items, expected_valid_dates) do
        post_date = Category.get_date(item)
        assert post_date == expected_date

        # Test database insertion
        dadi_params = %{
          title: Category.get_title(item),
          url: "http://c.dadi360.com" <> Category.get_link(item),
          post_date: post_date,
          ref_category_id: ref_category.id,
          phone: nil,
          content: nil
        }

        changeset = Dadi.changeset(%Dadi{}, dadi_params)
        assert changeset.valid?, "Valid date #{post_date} should create valid changeset"
      end

      # Test invalid dates
      invalid_items = Enum.drop(items, 2)
      
      for item <- invalid_items do
        post_date = Category.get_date(item)
        assert post_date == nil, "Invalid date should return nil"

        # Test that nil dates create invalid changesets
        dadi_params = %{
          title: Category.get_title(item),
          url: "http://c.dadi360.com" <> Category.get_link(item),
          post_date: post_date,
          ref_category_id: ref_category.id,
          phone: nil,
          content: nil
        }

        changeset = Dadi.changeset(%Dadi{}, dadi_params)
        refute changeset.valid?, "Nil date should create invalid changeset"
        assert changeset.errors[:post_date] == {"can't be blank", [validation: :required]}
      end
    end

    test "validates production date restriction logic", %{ref_category: ref_category} do
      # Test the production date restriction logic
      original_env = Mix.env()
      Mix.env(:prod)

      # Get yesterday's date (target date)
      target_date = Efl.TimeUtil.target_date()

      html_with_yesterday = """
      <tr class="bg_small_yellow">
        <td class="topictitle">
          <a href="/c/posts/list/yesterday.page">
            <span class="topictitlehl">Yesterday's Post</span>
          </a>
        </td>
        <td class="postdetails">#{target_date |> Timex.format!("%m/%d/%Y", :strftime)}</td>
      </tr>
      """

      html_with_old_date = """
      <tr class="bg_small_yellow">
        <td class="topictitle">
          <a href="/c/posts/list/old.page">
            <span class="topictitlehl">Old Post</span>
          </a>
        </td>
        <td class="postdetails">1/1/2025</td>
      </tr>
      """

      # Test yesterday's date (should be valid in production)
      {:ok, yesterday_items} = Category.find_raw_items({:ok, html_with_yesterday})
      yesterday_item = List.first(yesterday_items)
      
      yesterday_title = Category.get_title(yesterday_item)
      yesterday_link = Category.get_link(yesterday_item)
      yesterday_date = Category.get_date(yesterday_item)

      assert yesterday_date == target_date

      yesterday_dadi_params = %{
        title: yesterday_title,
        url: "http://c.dadi360.com" <> yesterday_link,
        post_date: yesterday_date,
        ref_category_id: ref_category.id,
        phone: nil,
        content: nil
      }

      yesterday_changeset = Dadi.changeset(%Dadi{}, yesterday_dadi_params)
      assert yesterday_changeset.valid?, "Yesterday's date should be valid in production"

      # Test old date (should be invalid in production)
      {:ok, old_items} = Category.find_raw_items({:ok, html_with_old_date})
      old_item = List.first(old_items)
      
      old_title = Category.get_title(old_item)
      old_link = Category.get_link(old_item)
      old_date = Category.get_date(old_item)

      assert old_date == ~D[2025-01-01]

      old_dadi_params = %{
        title: old_title,
        url: "http://c.dadi360.com" <> old_link,
        post_date: old_date,
        ref_category_id: ref_category.id,
        phone: nil,
        content: nil
      }

      old_changeset = Dadi.changeset(%Dadi{}, old_dadi_params)
      refute old_changeset.valid?, "Old date should be invalid in production"
      assert old_changeset.errors[:post_date] == {"can't be blank", []}

      # Restore original environment
      Mix.env(original_env)
    end
  end

  describe "performance and reliability integration tests" do
    test "handles large batch of date parsing operations", %{ref_category: ref_category} do
      # Test processing a large number of items with various dates
      dates = [
        "1/1/2025", "2/15/2025", "3/31/2025", "4/1/2025", "5/15/2025",
        "6/30/2025", "7/4/2025", "8/15/2025", "9/16/2025", "10/31/2025",
        "11/15/2025", "12/25/2025"
      ]

      html_items = for {date, index} <- Enum.with_index(dates, 1) do
        """
        <tr class="bg_small_yellow">
          <td class="topictitle">
            <a href="/c/posts/list/#{index}.page">
              <span class="topictitlehl">Item #{index}</span>
            </a>
          </td>
          <td class="postdetails">#{date}</td>
        </tr>
        """
      end

      combined_html = Enum.join(html_items, "\n")
      {:ok, items} = Category.find_raw_items({:ok, combined_html})
      
      assert length(items) == length(dates)

      # Process all items
      valid_count = 0
      for item <- items do
        title = Category.get_title(item)
        link = Category.get_link(item)
        post_date = Category.get_date(item)

        if post_date != nil do
          dadi_params = %{
            title: title,
            url: "http://c.dadi360.com" <> link,
            post_date: post_date,
            ref_category_id: ref_category.id,
            phone: nil,
            content: nil
          }

          changeset = Dadi.changeset(%Dadi{}, dadi_params)
          if changeset.valid? do
            valid_count = valid_count + 1
          end
        end
      end

      # All items should be valid
      assert valid_count == length(dates), "All #{length(dates)} items should be valid"
    end

    test "maintains data integrity across the complete flow", %{ref_category: ref_category} do
      # Test that data integrity is maintained from HTML parsing to database storage
      test_html = """
      <tr class="bg_small_yellow">
        <td class="topictitle">
          <a href="/c/posts/list/integrity.page">
            <span class="topictitlehl">Data Integrity Test</span>
          </a>
        </td>
        <td class="postdetails">9/16/2025</td>
      </tr>
      """

      # Step 1: Parse and extract
      {:ok, items} = Category.find_raw_items({:ok, test_html})
      item = List.first(items)
      
      original_title = Category.get_title(item)
      original_link = Category.get_link(item)
      original_date = Category.get_date(item)

      # Step 2: Create and validate changeset
      dadi_params = %{
        title: original_title,
        url: "http://c.dadi360.com" <> original_link,
        post_date: original_date,
        ref_category_id: ref_category.id,
        phone: nil,
        content: nil
      }

      changeset = Dadi.changeset(%Dadi{}, dadi_params)
      assert changeset.valid?

      # Step 3: Insert into database
      {:ok, dadi} = Repo.insert(changeset)

      # Step 4: Verify data integrity
      assert dadi.title == original_title
      assert dadi.url == "http://c.dadi360.com" <> original_link
      assert dadi.post_date == original_date
      assert dadi.ref_category_id == ref_category.id

      # Step 5: Retrieve from database and verify
      retrieved_dadi = Repo.get(Dadi, dadi.id)
      assert retrieved_dadi.title == original_title
      assert retrieved_dadi.url == "http://c.dadi360.com" <> original_link
      assert retrieved_dadi.post_date == original_date
      assert retrieved_dadi.ref_category_id == ref_category.id
    end
  end
end
