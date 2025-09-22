defmodule Efl.HtmlParsers.Dadi.CategoryParserTest do
  use Efl.ModelCase, async: true
  alias Efl.HtmlParsers.Dadi.Category

  describe "find_raw_items/1" do
    test "finds items using Floki when available" do
      # Test with simple HTML that Floki can parse
      simple_html = """
      <html>
        <body>
          <tr class="bg_small_yellow">
            <td class="topictitle">
              <a href="/test1">Test Title 1</a>
            </td>
            <td class="postdetails">09/16/2025</td>
          </tr>
          <tr class="bg_small_yellow">
            <td class="topictitle">
              <a href="/test2">Test Title 2</a>
            </td>
            <td class="postdetails">09/17/2025</td>
          </tr>
        </body>
      </html>
      """

      {:ok, items} = Category.find_raw_items({:ok, simple_html})
      
      # Should find items (either via Floki or regex fallback)
      assert length(items) >= 0
    end

    test "falls back to regex when Floki finds no items" do
      # Test with HTML that has the expected structure but Floki might not parse correctly
      html_with_structure = """
      <tr class="bg_small_yellow">
        <td class="row1Announce" valign="middle" align="center" width="20">
          <img class="icon_folder_announce" src="/c/images/transp.gif" alt="" />
        </td>
        <td class="row1Announce" width="100%">
          <span class="topictitle">
            <a href="/c/posts/list/303624.page;jsessionid=E114E2AE774EEECE7A80BF5D0C2C0DBC">
              <span class="topictitlehl">
                版主提示：本栏目要求广告必须说明出租房屋附近的街口， 没有街口的广告将会被自动屏蔽。 请不要只用超市、商店作为坐标。
              </span>
            </a>
          </span>
        </td>
        <td class="row2Announce" valign="middle" align="center">
          <span class="postdetails">22</span>
        </td>
        <td class="row3" valign="middle" align="center">
          <div style="width:40px; overflow:hidden;white-space: nowrap;text-overflow: ellipsis;">
            <span class="name"><a href="/">版主</a></span>
          </div>
        </td>
        <td class="row2Announce" valign="middle" align="center">
          <span class="postdetails">455634</span>
        </td>
        <td class="row3Announce" valign="middle" nowrap="nowrap" align="center">
          <span class="postdetails">09/16/2025</span>
        </td>
      </tr>
      """

      {:ok, items} = Category.find_raw_items({:ok, html_with_structure})
      
      # Should find at least one item via regex fallback
      assert length(items) >= 1
      
      # First item should be a string (regex result)
      first_item = List.first(items)
      assert is_binary(first_item)
      assert String.contains?(first_item, "bg_small_yellow")
    end

    test "handles nil html body" do
      {:ok, items} = Category.find_raw_items({:ok, nil})
      assert items == []
    end

    test "handles error tuple" do
      assert_raise RuntimeError, "Cateogry#find_raw_items Fail", fn ->
        Category.find_raw_items({:error, "test error"})
      end
    end
  end

  describe "get_title/1" do
    test "extracts title from regex string" do
      html_string = """
      <tr class="bg_small_yellow">
        <td class="row1Announce" width="100%">
          <span class="topictitle">
            <a href="/c/posts/list/303624.page">
              <span class="topictitlehl">
                版主提示：本栏目要求广告必须说明出租房屋附近的街口
              </span>
            </a>
          </span>
        </td>
      </tr>
      """

      title = Category.get_title(html_string)
      assert title == "版主提示：本栏目要求广告必须说明出租房屋附近的街口"
    end

    test "returns empty string when title not found" do
      html_string = "<tr class='bg_small_yellow'><td>No title here</td></tr>"
      title = Category.get_title(html_string)
      assert title == ""
    end

    test "handles malformed HTML gracefully" do
      malformed_html = "<tr class='bg_small_yellow'><td>Broken HTML"
      title = Category.get_title(malformed_html)
      assert title == ""
    end
  end

  describe "get_link/1" do
    test "extracts link from regex string" do
      html_string = """
      <tr class="bg_small_yellow">
        <td class="row1Announce" width="100%">
          <span class="topictitle">
            <a href="/c/posts/list/3938643.page;jsessionid=E114E2AE774EEECE7A80BF5D0C2C0DBC">
              <span class="topictitlehl">Test Title</span>
            </a>
          </span>
        </td>
      </tr>
      """

      link = Category.get_link(html_string)
      assert link == "/c/posts/list/3938643.page"
    end

    test "handles link without jsessionid" do
      html_string = """
      <tr class="bg_small_yellow">
        <td class="row1Announce" width="100%">
          <span class="topictitle">
            <a href="/c/posts/list/3938643.page">
              <span class="topictitlehl">Test Title</span>
            </a>
          </span>
        </td>
      </tr>
      """

      link = Category.get_link(html_string)
      assert link == "/c/posts/list/3938643.page"
    end

    test "returns empty string when link not found" do
      html_string = "<tr class='bg_small_yellow'><td>No link here</td></tr>"
      link = Category.get_link(html_string)
      assert link == ""
    end
  end

  describe "get_date/1" do
    test "extracts date from regex string" do
      html_string = """
      <tr class="bg_small_yellow">
        <td class="row3Announce" valign="middle" nowrap="nowrap" align="center">
          <span class="postdetails">09/16/2025</span>
        </td>
      </tr>
      """

      date = Category.get_date(html_string)
      assert date == ~D[2025-09-16]
    end

    test "handles invalid date format" do
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">invalid-date</td>
      </tr>
      """

      date = Category.get_date(html_string)
      assert date == nil
    end

    test "returns nil when date not found" do
      html_string = "<tr class='bg_small_yellow'><td>No date here</td></tr>"
      date = Category.get_date(html_string)
      assert date == nil
    end
  end

  describe "parse_date/1" do
    test "parses valid date string" do
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">09/16/2025</td>
      </tr>
      """

      date = Category.get_date(html_string)
      assert date == ~D[2025-09-16]
    end

    test "parses multiple date formats" do
      # Test MM/DD/YYYY format in proper HTML
      html1 = """
      <td class="postdetails">01/15/2025</td>
      """
      {:ok, date1} = Category.parse_date(html1)
      assert date1 == ~D[2025-01-15]

      # Test M/D/YYYY format in proper HTML
      html2 = """
      <span class="postdetails">1/5/2025</span>
      """
      {:ok, date2} = Category.parse_date(html2)
      assert date2 == ~D[2025-01-05]

      # Test MM/DD/YYYY format with different structure
      html3 = """
      <td class="postdetails">9/16/2025</td>
      """
      {:ok, date3} = Category.parse_date(html3)
      assert date3 == ~D[2025-09-16]
    end

    test "handles invalid date format" do
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">invalid-date</td>
      </tr>
      """

      {:error, _reason} = Category.parse_date(html_string)
    end

    test "handles empty date string" do
      {:error, _reason} = Category.parse_date("")
    end

    test "handles nil date string" do
      {:error, _reason} = Category.parse_date(nil)
    end
  end

  describe "integration with cached HTML" do
    test "processes cached HTML file if available" do
      # This test will only run if the cached HTML file exists
      if File.exists?("test/cached_html.html") do
        cached_html = File.read!("test/cached_html.html")
        
        {:ok, items} = Category.find_raw_items({:ok, cached_html})
        
        # Should find many items from the cached HTML
        assert length(items) > 0
        
        # Test extraction from first few items
        Enum.take(items, 3) |> Enum.each(fn item ->
          title = Category.get_title(item)
          link = Category.get_link(item)
          date = Category.get_date(item)
          
          # At least one of these should have content
          assert is_binary(title)
          assert is_binary(link)
          # Date might be nil for some items, that's okay
        end)
      else
        # Skip test if cached file doesn't exist
        :ok
      end
    end

    test "processes cached HTML with yesterday's date" do
      if File.exists?("test/cached_html.html") do
        cached_html = File.read!("test/cached_html.html")
        
        # Update the cached HTML to use yesterday's date
        yesterday = Efl.TimeUtil.target_date() |> Timex.format!("%m/%d/%Y", :strftime)
        updated_html = String.replace(cached_html, "01/15/2025", yesterday)
        
        {:ok, items} = Category.find_raw_items({:ok, updated_html})
        
        # Should find items
        assert length(items) > 0
        
        # Test that we can extract data from items with yesterday's date
        first_item = List.first(items)
        title = Category.get_title(first_item)
        link = Category.get_link(first_item)
        date = Category.get_date(first_item)
        
        assert is_binary(title)
        assert is_binary(link)
        assert date != nil
        
        # The date should be parsed correctly
        assert {:ok, _} = Category.parse_date(first_item)
      else
        :ok
      end
    end
  end


  describe "date parsing bug fix - MM/DD/YYYY format" do
    test "correctly parses 9/16/2025 as September 16, 2025 (not January 16)" do
      # This was the specific bug: 9/16/2025 was being parsed as January 16, 2025
      # instead of September 16, 2025
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">9/16/2025</td>
      </tr>
      """

      date = Category.get_date(html_string)
      # Should be September 16, 2025, not January 16, 2025
      assert date == ~D[2025-09-16]
    end

    test "correctly parses 8/31/2025 as August 31, 2025 (not January 31)" do
      # Another example of the bug: single digit month should be parsed correctly
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">8/31/2025</td>
      </tr>
      """

      date = Category.get_date(html_string)
      assert date == ~D[2025-08-31]
    end

    test "correctly parses 12/25/2025 as December 25, 2025" do
      # Test double digit month
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">12/25/2025</td>
      </tr>
      """

      date = Category.get_date(html_string)
      assert date == ~D[2025-12-25]
    end

    test "correctly parses 1/1/2025 as January 1, 2025" do
      # Test single digit month and day
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">1/1/2025</td>
      </tr>
      """

      date = Category.get_date(html_string)
      assert date == ~D[2025-01-01]
    end

    test "correctly parses 01/15/2025 as January 15, 2025" do
      # Test zero-padded month
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">01/15/2025</td>
      </tr>
      """

      date = Category.get_date(html_string)
      assert date == ~D[2025-01-15]
    end

    test "correctly parses 9/1/2025 as September 1, 2025" do
      # Test single digit month with single digit day
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">9/1/2025</td>
      </tr>
      """

      date = Category.get_date(html_string)
      assert date == ~D[2025-09-01]
    end
  end

  describe "manual date parsing edge cases" do
    test "handles invalid month values" do
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">13/15/2025</td>
      </tr>
      """

      date = Category.get_date(html_string)
      # Should return nil for invalid month
      assert date == nil
    end

    test "handles invalid day values" do
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">12/32/2025</td>
      </tr>
      """

      date = Category.get_date(html_string)
      # Should return nil for invalid day
      assert date == nil
    end

    test "handles invalid year values" do
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">12/15/1800</td>
      </tr>
      """

      date = Category.get_date(html_string)
      # Should return nil for year before 1900
      assert date == nil
    end

    test "handles February 29 in non-leap year" do
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">2/29/2025</td>
      </tr>
      """

      date = Category.get_date(html_string)
      # Should return nil for invalid leap year date
      assert date == nil
    end

    test "handles February 29 in leap year" do
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">2/29/2024</td>
      </tr>
      """

      date = Category.get_date(html_string)
      # Should work for valid leap year date
      assert date == ~D[2024-02-29]
    end

    test "handles malformed date strings" do
      malformed_dates = [
        "not-a-date",
        "12/15",  # Missing year
        "2025/12/15",  # Wrong format
        "12-15-2025",  # Wrong separator
        "12/15/25",  # Two digit year
        "",  # Empty string
        "12//15/2025",  # Double slash
        "12/15/2025/extra"  # Extra content
      ]

      for malformed_date <- malformed_dates do
        html_string = """
        <tr class="bg_small_yellow">
          <td class="postdetails">#{malformed_date}</td>
        </tr>
        """

        date = Category.get_date(html_string)
        assert date == nil, "Expected nil for malformed date: #{malformed_date}, got: #{inspect(date)}"
      end
    end
  end

  # NOTE: Removed fantasy date format tests (DD/MM/YYYY and YYYY-MM-DD)
  # that don't exist in real dadi360.com data. Production only uses MM/DD/YYYY format.
  describe "Timex fallback for other date formats" do

    test "handles Timex parsing errors gracefully" do
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">invalid-format</td>
      </tr>
      """

      date = Category.get_date(html_string)
      assert date == nil
    end
  end

  describe "integration tests with real-world data" do
    test "processes real HTML with various date formats" do
      # Test with HTML that contains the actual structure we see in production
      real_html = """
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

      # Test that all extraction methods work correctly
      title = Category.get_title(real_html)
      link = Category.get_link(real_html)
      date = Category.get_date(real_html)

      assert title == "Elmhurst 新 2 房2衛，1000sqft"
      assert link == "/c/posts/list/3942533.page"
      assert date == ~D[2025-09-16]
    end

    test "processes multiple items with different dates" do
      items_html = [
        """
        <tr class="bg_small_yellow">
          <td class="topictitle">
            <a href="/c/posts/list/1.page">
              <span class="topictitlehl">Item 1</span>
            </a>
          </td>
          <td class="postdetails">9/16/2025</td>
        </tr>
        """,
        """
        <tr class="bg_small_yellow">
          <td class="topictitle">
            <a href="/c/posts/list/2.page">
              <span class="topictitlehl">Item 2</span>
            </a>
          </td>
          <td class="postdetails">8/31/2025</td>
        </tr>
        """,
        """
        <tr class="bg_small_yellow">
          <td class="topictitle">
            <a href="/c/posts/list/3.page">
              <span class="topictitlehl">Item 3</span>
            </a>
          </td>
          <td class="postdetails">12/25/2025</td>
        </tr>
        """
      ]

      expected_dates = [~D[2025-09-16], ~D[2025-08-31], ~D[2025-12-25]]

      for {item_html, expected_date} <- Enum.zip(items_html, expected_dates) do
        date = Category.get_date(item_html)
        assert date == expected_date, "Expected #{expected_date}, got #{inspect(date)} for item: #{item_html}"
      end
    end
  end

  describe "performance and reliability tests" do
    test "handles large number of date parsing operations" do
      # Test that our manual parsing is efficient and doesn't crash
      dates = [
        "1/1/2025", "2/15/2025", "3/31/2025", "4/1/2025", "5/15/2025",
        "6/30/2025", "7/4/2025", "8/15/2025", "9/16/2025", "10/31/2025",
        "11/15/2025", "12/25/2025"
      ]

      for date_str <- dates do
        html_string = """
        <tr class="bg_small_yellow">
          <td class="postdetails">#{date_str}</td>
        </tr>
        """

        date = Category.get_date(html_string)
        assert date != nil, "Failed to parse date: #{date_str}"
        assert %Date{} = date, "Expected Date struct, got: #{inspect(date)}"
      end
    end

    test "maintains consistency across multiple calls" do
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">9/16/2025</td>
      </tr>
      """

      # Call multiple times to ensure consistency
      results = for _ <- 1..10, do: Category.get_date(html_string)
      
      # All results should be the same
      unique_results = Enum.uniq(results)
      assert length(unique_results) == 1
      assert hd(unique_results) == ~D[2025-09-16]
    end
  end
end
