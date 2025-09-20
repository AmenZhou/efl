defmodule Efl.HtmlParsers.Dadi.Post do
  alias Efl.HtmlParsers.Dadi.Post, as: PostParser
  alias Efl.PhoneUtil
  require IEx
  require Logger

  defstruct [:url, :phone, :content]

  def parse_post(url) do
    try do
      case html(url) do
        { :ok, body } ->
          Logger.info("Post parsed one url: #{url}")
          content = try do
            case Floki.parse_document(body) do
              {:ok, parsed_doc} ->
                content_text = Floki.find(".postbody", parsed_doc)
                |> Floki.text
                |> String.trim
                
                if content_text == "" do
                  Logger.warning("No content found with .postbody selector for URL: #{url}")
                  # Try alternative selectors
                  alternative_content = try_alternative_selectors(parsed_doc)
                  if alternative_content != "" do
                    Logger.info("Found content with alternative selector: #{String.slice(alternative_content, 0, 100)}...")
                    alternative_content
                  else
                    Logger.warning("No content found with any selector for URL: #{url}")
                    ""
                  end
                else
                  Logger.info("Found content with .postbody selector: #{String.slice(content_text, 0, 100)}...")
                  content_text
                end
              {:error, reason} ->
                Logger.error("Failed to parse HTML document: #{inspect(reason)}")
                ""
            end
          rescue
            ex ->
              Logger.warning("Failed to extract content from post body: #{inspect(ex)}")
              ""
          end

          phone = PhoneUtil.find_phone_from_content(content)

          %PostParser{
            content: content,
            url: url,
            phone: phone
          }
        { :error, message } ->
          log_info = "Error PostParser.Dadi.Post HTML parse error, #{message}"
          Logger.error(log_info)
          Efl.Mailer.send_alert(log_info)
          %PostParser{url: url, content: "", phone: ""}
      end
    rescue
      ex ->
        log_info = "Post#parse_post url: #{url}, message: #{inspect(ex)}"
        Logger.error(log_info)
        Efl.Mailer.send_alert(log_info)
        %PostParser{url: url, content: "", phone: ""}
    end
  end

  defp try_alternative_selectors(parsed_doc) do
    # Try different selectors that might contain the post content
    selectors = [
      ".postbody div",
      ".postbody div div",
      "div.postbody",
      ".row1 .postbody",
      "td.postbody",
      ".postbody div[oncopy]"
    ]
    
    Enum.find_value(selectors, fn selector ->
      case Floki.find(selector, parsed_doc) do
        [] -> nil
        elements ->
          content = elements
          |> Floki.text
          |> String.trim
          
          if content != "" do
            Logger.info("Found content with selector '#{selector}': #{String.slice(content, 0, 100)}...")
            content
          else
            nil
          end
      end
    end) || ""
  end

  defp html(url) do
    body = Efl.MyHttp.request(url)
    { :ok, body }
  end
end
