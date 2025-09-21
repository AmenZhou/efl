defmodule Efl.HtmlParsers.Dadi.DateParsingTest do
  use Efl.ModelCase, async: true
  alias Efl.HtmlParsers.Dadi.Category

  describe "date parsing bug fix - MM/DD/YYYY format" do
    test "correctly parses 9/16/2025 as September 16, 2025 (not January 16)" do
      # This was the specific bug: 9/16/2025 was being parsed as January 16, 2025
      # instead of September 16, 2025 due to Timex format issue
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

    test "correctly parses 10/31/2025 as October 31, 2025" do
      # Test double digit month and day
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">10/31/2025</td>
      </tr>
      """

      date = Category.get_date(html_string)
      assert date == ~D[2025-10-31]
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

    test "handles edge case month/day combinations" do
      # Test various month/day combinations that might cause issues
      test_cases = [
        {"1/31/2025", ~D[2025-01-31]},  # January has 31 days
        {"2/28/2025", ~D[2025-02-28]},  # February has 28 days in non-leap year
        {"2/29/2024", ~D[2024-02-29]},  # February has 29 days in leap year
        {"4/30/2025", ~D[2025-04-30]},  # April has 30 days
        {"4/31/2025", nil},  # April doesn't have 31 days
        {"6/30/2025", ~D[2025-06-30]},  # June has 30 days
        {"6/31/2025", nil},  # June doesn't have 31 days
        {"9/30/2025", ~D[2025-09-30]},  # September has 30 days
        {"9/31/2025", nil},  # September doesn't have 31 days
        {"11/30/2025", ~D[2025-11-30]}, # November has 30 days
        {"11/31/2025", nil}, # November doesn't have 31 days
      ]

      for {date_str, expected} <- test_cases do
        html_string = """
        <tr class="bg_small_yellow">
          <td class="postdetails">#{date_str}</td>
        </tr>
        """

        date = Category.get_date(html_string)
        assert date == expected, "Expected #{inspect(expected)} for date #{date_str}, got: #{inspect(date)}"
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

    test "handles concurrent date parsing" do
      # Test that our parsing is thread-safe
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">9/16/2025</td>
      </tr>
      """

      # Simulate concurrent parsing
      tasks = for _ <- 1..20 do
        Task.async(fn -> Category.get_date(html_string) end)
      end

      results = Task.await_many(tasks)
      
      # All results should be the same
      unique_results = Enum.uniq(results)
      assert length(unique_results) == 1
      assert hd(unique_results) == ~D[2025-09-16]
    end
  end

  describe "integration with real-world data" do
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

      # Test that date extraction works correctly
      date = Category.get_date(real_html)
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

  describe "regression tests for the specific bug" do
    test "ensures 9/16/2025 is never parsed as January 16, 2025" do
      # This test specifically prevents regression of the bug we fixed
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">9/16/2025</td>
      </tr>
      """

      date = Category.get_date(html_string)
      
      # Ensure it's September 16, not January 16
      assert date == ~D[2025-09-16]
      refute date == ~D[2025-01-16], "Regression: 9/16/2025 was parsed as January 16, 2025"
    end

    test "ensures 8/31/2025 is never parsed as January 31, 2025" do
      # Another regression test for the same bug pattern
      html_string = """
      <tr class="bg_small_yellow">
        <td class="postdetails">8/31/2025</td>
      </tr>
      """

      date = Category.get_date(html_string)
      
      # Ensure it's August 31, not January 31
      assert date == ~D[2025-08-31]
      refute date == ~D[2025-01-31], "Regression: 8/31/2025 was parsed as January 31, 2025"
    end

    test "validates that manual parsing is used for MM/DD/YYYY format" do
      # This test ensures our manual parsing is being used instead of Timex
      # for MM/DD/YYYY format by testing edge cases that would fail with Timex
      test_cases = [
        "1/1/2025",   # Single digit month and day
        "9/16/2025",  # Single digit month, double digit day
        "12/1/2025",  # Double digit month, single digit day
        "12/25/2025"  # Double digit month and day
      ]

      for date_str <- test_cases do
        html_string = """
        <tr class="bg_small_yellow">
          <td class="postdetails">#{date_str}</td>
        </tr>
        """

        date = Category.get_date(html_string)
        assert date != nil, "Failed to parse date: #{date_str}"
        assert %Date{} = date, "Expected Date struct, got: #{inspect(date)}"
        
        # Ensure the date makes sense (not January when month is > 1)
        [month_str, day_str, year_str] = String.split(date_str, "/")
        month = String.to_integer(month_str)
        day = String.to_integer(day_str)
        year = String.to_integer(year_str)
        
        expected_date = Date.new!(year, month, day)
        assert date == expected_date, "Expected #{expected_date}, got #{date} for #{date_str}"
      end
    end
  end
end
