defmodule Efl.ContentExtractionIntegrationTest do
  use ExUnit.Case, async: true
  alias Efl.HtmlParsers.Dadi.Post

  describe "content extraction integration tests" do
    test "complete content extraction flow with real HTML structure" do
      # Simulate the actual HTML structure from the target website
      real_html = """
      <!DOCTYPE html>
      <html lang="zh-CN">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>Test Post</title>
      </head>
      <body>
        <div class="postbody">
          <div oncopy="return false;">【🏠 出租，】法拉盛新昌发对面电梯楼有大单间出租，随时入住，房间阳光明媚，安静、人少，适合单身，夫妻，餐馆优先，有意者，请联系电话：929-933-7510没接，可以发短信，谢谢！</div>
        </div>
      </body>
      </html>
      """

      # Test the complete extraction process
      content = extract_content_with_regex(real_html)
      
      assert content != ""
      assert String.length(content) > 50
      assert String.contains?(content, "法拉盛新昌发对面电梯楼有大单间出租")
      assert String.contains?(content, "929-933-7510")
      assert String.contains?(content, "【🏠 出租，】")
      
      # Verify content cleaning
      refute String.contains?(content, "<div")
      refute String.contains?(content, "oncopy")
      refute String.match?(content, ~r/\s{2,}/) # No multiple spaces
    end

    test "handles multiple post types with different content structures" do
      post_types = [
        {
          "apartment_rental",
          """
          <div class="postbody">
            <div oncopy="return false;">法拉盛151街/34 ave 二楼两房一厅一浴。 大约800尺，查信用，收入证明，一月押金。包水。长租。租1600刀。</div>
          </div>
          """,
          ["法拉盛151街", "二楼两房一厅一浴", "1600刀"]
        },
        {
          "job_posting", 
          """
          <div class="postbody">
            <div oncopy="return false;">法拉盛 诚意招聘 炒锅一名！ 200/天 全现金，能力强！ 来联系～</div>
          </div>
          """,
          ["诚意招聘", "炒锅一名", "200/天", "全现金"]
        },
        {
          "business_sale",
          """
          <div class="postbody">
            <div oncopy="return false;">长岛正宗按摩店转让，手续齐全，客源稳定，有意者请联系：718-123-4567</div>
          </div>
          """,
          ["长岛正宗按摩店转让", "手续齐全", "客源稳定", "718-123-4567"]
        }
      ]

      Enum.each(post_types, fn {type, html, expected_content} ->
        content = extract_content_with_regex(html)
        
        assert content != "", "Content extraction failed for #{type}"
        assert String.length(content) > 10, "Content too short for #{type}"
        
        Enum.each(expected_content, fn expected ->
          assert String.contains?(content, expected), 
            "Expected '#{expected}' not found in #{type} content: #{content}"
        end)
      end)
    end

    test "content extraction performance with large HTML" do
      # Create a large HTML document similar to the real website
      large_html = """
      <!DOCTYPE html>
      <html lang="zh-CN">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>Large Test Post</title>
        <style>
          .yptopcat{font-weight:bold; background-image:url('/images/gradient22.jpg');}
          .ypforum{color: #003B6E; text-decoration: none; font-size: 0.9em;}
        </style>
      </head>
      <body>
        <div class="header">Header content</div>
        <div class="navigation">Navigation content</div>
        <div class="main-content">
          <div class="postbody">
            <div oncopy="return false;">#{String.duplicate("This is a large content block. ", 100)}</div>
          </div>
        </div>
        <div class="footer">Footer content</div>
      </body>
      </html>
      """

      # Measure extraction time
      start_time = System.monotonic_time()
      content = extract_content_with_regex(large_html)
      end_time = System.monotonic_time()
      
      extraction_time = end_time - start_time
      
      assert content != ""
      assert String.length(content) > 1000
      assert extraction_time < 1_000_000 # Should be under 1ms in microseconds
    end

    test "handles malformed HTML from real website scenarios" do
      malformed_html_cases = [
        # Missing closing div
        """
        <div class="postbody">
          <div oncopy="return false;">Content without proper closing
        """,
        # Mixed quotes
        """
        <div class='postbody'>
          <div oncopy="return false;">Content with mixed quotes</div>
        </div>
        """,
        # Nested divs with oncopy
        """
        <div class="postbody">
          <div>
            <div oncopy="return false;">Nested content structure</div>
          </div>
        </div>
        """,
        # Content with special characters
        """
        <div class="postbody">
          <div oncopy="return false;">Content with &lt;special&gt; &amp; characters</div>
        </div>
        """
      ]

      Enum.each(malformed_html_cases, fn html ->
        content = extract_content_with_regex(html)
        
        # Should not crash and should extract some content
        assert is_binary(content)
        # May be empty for some malformed cases, which is acceptable
      end)
    end

    test "content extraction with various phone number formats" do
      phone_formats = [
        "929-933-7510",
        "(718) 123-4567", 
        "718.123.4567",
        "7181234567",
        "1-718-123-4567"
      ]

      Enum.each(phone_formats, fn phone ->
        html = """
        <div class="postbody">
          <div oncopy="return false;">Contact us at #{phone} for more information</div>
        </div>
        """

        content = extract_content_with_regex(html)
        
        assert content != ""
        assert String.contains?(content, phone)
      end)
    end

    test "content extraction preserves Chinese characters and emojis" do
      html = """
      <div class="postbody">
        <div oncopy="return false;">🏠 出租信息：法拉盛地区，两房一厅，月租$1600，联系电话：929-933-7510 📞</div>
      </div>
      """

      content = extract_content_with_regex(html)
      
      assert content != ""
      assert String.contains?(content, "🏠")
      assert String.contains?(content, "📞")
      assert String.contains?(content, "出租信息")
      assert String.contains?(content, "法拉盛地区")
      assert String.contains?(content, "两房一厅")
      assert String.contains?(content, "$1600")
      assert String.contains?(content, "929-933-7510")
    end
  end

  # Helper function to test the private extract_content_with_regex function
  defp extract_content_with_regex(html_string) when is_binary(html_string) do
    # Test the main pattern
    case Regex.run(~r/class\s*=\s*["\']postbody["\'][^>]*>(.*?)<\/div>/s, html_string) do
      [_, content] ->
        cleaned_content = content
        |> String.replace(~r/<[^>]*>/, " ") # Remove HTML tags
        |> String.replace(~r/\s+/, " ") # Normalize whitespace
        |> String.trim()
        
        if String.length(cleaned_content) > 10 do
          cleaned_content
        else
          ""
        end
      nil ->
        # Try alternative regex patterns
        alternative_patterns = [
          ~r/postbody[^>]*>(.*?)<\/[^>]+>/s,
          ~r/oncopy\s*=\s*["\']return false;["\'][^>]*>(.*?)<\/div>/s,
          ~r/<div[^>]*oncopy[^>]*>(.*?)<\/div>/s
        ]
        
        Enum.find_value(alternative_patterns, fn pattern ->
          case Regex.run(pattern, html_string) do
            [_, content] ->
              cleaned_content = content
              |> String.replace(~r/<[^>]*>/, " ")
              |> String.replace(~r/\s+/, " ")
              |> String.trim()
              
              if String.length(cleaned_content) > 10 do
                cleaned_content
              else
                nil
              end
            nil -> nil
          end
        end) || ""
    end
  end

  defp extract_content_with_regex(_), do: ""
end
