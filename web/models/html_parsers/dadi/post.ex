defmodule Efl.HtmlParsers.Dadi.Post do
  alias Efl.HtmlParsers.Dadi.Post, as: HtmlParser
  alias Efl.PhoneUtil
  require IEx

  @http_config [
    ibrowse: [proxy_host: '97.77.104.22', proxy_port: 3128],
    timeout: 50_000
  ]

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
          phone: PhoneUtil.find_phone_from_content(content)
        }
      { :error, message } ->
        IO.puts("Error HtmlParsers.Dadi.Post HTML parse error, #{message}")
    end
  end
    
  defp html(url) do
    case HTTPotion.get(url, @http_config) do
      %{ body: body } ->
        { :ok, body }
      %{ message: message } ->
        { :error, message }
    end
  end
end
