defmodule Efl.HtmlParsers.Dadi.Post do
  alias Efl.HtmlParsers.Dadi.Post, as: HtmlParser
  require IEx

  def parse_posts(urls) do
    urls
    |> Enum.map(&parse_post(&1))
  end

  def async_parse_posts(urls) do
    urls
    |> Enum.map(fn(url) ->
      :timer.sleep(100)
      Task.async(HtmlParser, :parse_post, [url])
    end)
    |> Enum.map(fn(task) ->
      Task.await(task)
    end)
  end

  def parse_post(url) do
    case html(url) do
      { :ok, body } ->
        IO.puts("Post parsed one url: #{url}")
        content = body
                  |> Floki.find(".postbody")
                  |> Floki.text
                  |> String.strip
        %{
          content: content,
          url: url,
          phone: find_phone_from_content(content)
        }
      { :error, message } ->
        raise "Error HtmlParsers.Dadi.Post HTML parse error, #{message}"
    end
  end

  #Find and fetch the first phone number in the content
  defp find_phone_from_content(content) do
    ~r/(?<area_code>\d{3}).?(?<middle>\d{3}).?(?<last>\d{4})/
    |> Regex.named_captures(content)
    |> generate_phone_from_regex
  end

  defp generate_phone_from_regex(nil), do: nil

  #The arg is a map %{"area_code" => "222", "middle" => "222", "last" => "2222"}
  defp generate_phone_from_regex(regex) do
    Map.get(regex, "area_code")
    <> "-"
    <> Map.get(regex, "middle")
    <> "-"
    <> Map.get(regex, "last")
  end
    
  defp html(url) do
    case HTTPotion.get(
                       url,
                       [
                         ibrowse: [proxy_host: '167.205.3.63', proxy_port: 8080],
                         timeout: 10_000
                       ]
                     ) do
      %{ body: body } ->
        { :ok, body }
      %{ message: message } ->
        { :error, message }
    end
  end
end
