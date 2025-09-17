defmodule Efl.HtmlParserIntegrationTest do
  use Efl.ModelCase, async: false
  alias Efl.HtmlParsers.Dadi.Category
  alias Efl.RefCategory
  alias Efl.Repo

  describe "HTML Parser Integration Tests" do
    setup do
      # Ensure we have ref categories
      RefCategory.seeds()
      :ok
    end

    test "parser works with real HTML structure" do
      # Test with a realistic HTML structure that matches the actual website
      realistic_html = """
      <html>
        <body>
          <table class="forumline" cellspacing="1" cellpadding="4" width="100%" border="0">
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
            <tr class="bg_small_yellow">
              <td class="row1Announce" valign="middle" align="center" width="20">
                <img class="icon_folder_announce" src="/c/images/transp.gif" alt="" />
              </td>
              <td class="row1Announce" width="100%">
                <span class="topictitle">
                  <a href="/c/posts/list/3938643.page;jsessionid=DEF456">
                    <span class="topictitlehl">
                      法拉盛主街附近2房1厅出租
                    </span>
                  </a>
                </span>
              </td>
              <td class="row2Announce" valign="middle" align="center">
                <span class="postdetails">5</span>
              </td>
              <td class="row3" valign="middle" align="center">
                <div style="width:40px; overflow:hidden;white-space: nowrap;text-overflow: ellipsis;">
                  <span class="name"><a href="/">房东</a></span>
                </div>
              </td>
              <td class="row2Announce" valign="middle" align="center">
                <span class="postdetails">123456</span>
              </td>
              <td class="row3Announce" valign="middle" nowrap="nowrap" align="center">
                <span class="postdetails">09/15/2025</span>
              </td>
            </tr>
          </table>
        </body>
      </html>
      """

      {:ok, items} = Category.find_raw_items({:ok, realistic_html})
      
      # Should find 2 items
      assert length(items) == 2
      
      # Test first item
      first_item = List.first(items)
      title = Category.get_title(first_item)
      link = Category.get_link(first_item)
      date = Category.get_date(first_item)
      
      assert String.contains?(title, "版主提示")
      assert link == "/c/posts/list/303624.page"
      assert date == ~N[2025-09-16 00:00:00]
      
      # Test second item
      second_item = Enum.at(items, 1)
      title2 = Category.get_title(second_item)
      link2 = Category.get_link(second_item)
      date2 = Category.get_date(second_item)
      
      assert String.contains?(title2, "法拉盛主街附近")
      assert link2 == "/c/posts/list/3938643.page"
      assert date2 == ~N[2025-09-15 00:00:00]
    end

    test "parser handles empty HTML gracefully" do
      empty_html = "<html><body></body></html>"
      {:ok, items} = Category.find_raw_items({:ok, empty_html})
      assert items == []
    end

    test "parser handles HTML without expected structure" do
      different_html = """
      <html>
        <body>
          <div class="other-content">
            <p>Some content without the expected structure</p>
          </div>
        </body>
      </html>
      """

      {:ok, items} = Category.find_raw_items({:ok, different_html})
      assert items == []
    end

    test "parser works with cached HTML file if available" do
      if File.exists?("cached_html.html") do
        cached_html = File.read!("cached_html.html")
        
        {:ok, items} = Category.find_raw_items({:ok, cached_html})
        
        # Should find many items from the real cached HTML
        assert length(items) > 50  # The cached file had 90 items
        
        # Test that we can extract data from multiple items
        test_items = Enum.take(items, 5)
        
        Enum.each(test_items, fn item ->
          title = Category.get_title(item)
          link = Category.get_link(item)
          date = Category.get_date(item)
          
          # All items should have some data
          assert is_binary(title)
          assert is_binary(link)
          assert is_binary(link) and String.length(link) > 0
          
          # Most items should have valid dates
          if date do
            assert is_struct(date, NaiveDateTime)
          end
        end)
        
        # Test that we can process all items without errors
        processed_items = Enum.map(items, fn item ->
          %{
            title: Category.get_title(item),
            link: Category.get_link(item),
            date: Category.get_date(item)
          }
        end)
        
        assert length(processed_items) == length(items)
        
        # Verify we have some meaningful data
        titles_with_content = Enum.filter(processed_items, fn item ->
          String.length(item.title) > 0
        end)
        
        assert length(titles_with_content) > 0
      else
        # Skip test if cached file doesn't exist
        :ok
      end
    end

    test "parser fallback mechanism works correctly" do
      # Create HTML that will trigger the regex fallback
      html_that_triggers_fallback = """
      <tr class="bg_small_yellow">
        <td class="row1Announce" valign="middle" align="center" width="20">
          <img class="icon_folder_announce" src="/c/images/transp.gif" alt="" />
        </td>
        <td class="row1Announce" width="100%">
          <span class="topictitle">
            <a href="/c/posts/list/123456.page;jsessionid=TEST123">
              <span class="topictitlehl">
                Test Post Title
              </span>
            </a>
          </span>
        </td>
        <td class="row2Announce" valign="middle" align="center">
          <span class="postdetails">1</span>
        </td>
        <td class="row3" valign="middle" align="center">
          <div style="width:40px; overflow:hidden;white-space: nowrap;text-overflow: ellipsis;">
            <span class="name"><a href="/">TestUser</a></span>
          </div>
        </td>
        <td class="row2Announce" valign="middle" align="center">
          <span class="postdetails">789012</span>
        </td>
        <td class="row3Announce" valign="middle" nowrap="nowrap" align="center">
          <span class="postdetails">09/17/2025</span>
        </td>
      </tr>
      """

      {:ok, items} = Category.find_raw_items({:ok, html_that_triggers_fallback})
      
      # Should find the item via regex fallback
      assert length(items) == 1
      
      item = List.first(items)
      assert is_binary(item)  # Should be a string from regex, not Floki element
      
      # Test data extraction
      title = Category.get_title(item)
      link = Category.get_link(item)
      date = Category.get_date(item)
      
      assert title == "Test Post Title"
      assert link == "/c/posts/list/123456.page"
      assert date == ~N[2025-09-17 00:00:00]
    end
  end
end
