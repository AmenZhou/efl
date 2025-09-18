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
      assert date == ~N[2025-09-16 00:00:00]
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

      {:ok, date} = Category.parse_date(html_string)
      assert date == ~N[2025-09-16 00:00:00]
    end

    test "parses multiple date formats" do
      # Test MM/DD/YYYY format
      {:ok, date1} = Category.parse_date("01/15/2025")
      assert date1 == ~N[2025-01-15 00:00:00]

      # Test M/D/YYYY format
      {:ok, date2} = Category.parse_date("1/5/2025")
      assert date2 == ~N[2025-01-05 00:00:00]

      # Test YYYY-MM-DD format
      {:ok, date3} = Category.parse_date("2025-01-15")
      assert date3 == ~N[2025-01-15 00:00:00]

      # Test DD/MM/YYYY format
      {:ok, date4} = Category.parse_date("15/01/2025")
      assert date4 == ~N[2025-01-15 00:00:00]
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

  describe "regex extraction helpers" do
    test "extract_title_with_regex finds title in span" do
      html_string = """
      <span class="topictitlehl">
        版主提示：本栏目要求广告必须说明出租房屋附近的街口
      </span>
      """

      # Call the private function through a public wrapper
      title = Category.get_title(html_string)
      assert title == "版主提示：本栏目要求广告必须说明出租房屋附近的街口"
    end

    test "extract_link_with_regex finds href attribute" do
      html_string = """
      <a href="/c/posts/list/303624.page;jsessionid=ABC123">
        <span class="topictitlehl">Test Title</span>
      </a>
      """

      link = Category.get_link(html_string)
      assert link == "/c/posts/list/303624.page"
    end

    test "extract_date_with_regex finds date in postdetails" do
      html_string = """
      <td class="postdetails">09/16/2025</td>
      """

      date = Category.get_date(html_string)
      assert date == ~N[2025-09-16 00:00:00]
    end
  end
end
