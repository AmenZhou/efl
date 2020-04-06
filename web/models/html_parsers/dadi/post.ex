defmodule Efl.HtmlParsers.Dadi.Post do
  alias Efl.HtmlParsers.Dadi.Post, as: PostParser
  alias Efl.PhoneUtil
  require IEx
  require Logger

  defstruct [:url, :phone, :content]

  @http_interval 1_000

  def parse_posts(urls) do
    urls
    |> Enum.map(&parse_post(&1))
  end

  def async_parse_posts(urls) do
    urls
    |> Enum.map(fn(url) ->
      :timer.sleep(10_000)
      Task.async(PostParser, :parse_post, [url])
    end)
    |> Enum.map(fn(task) ->
      Task.await(task)
    end)
  end

  def parse_post(url) do
    :timer.sleep(@http_interval)
    try do
      case html(url) do
        { :ok, body } ->
          IO.puts("Post parsed one url: #{url}")
          content = body
                    |> Floki.find(".postbody")
                    |> Floki.text
                    |> String.strip

          phone = PhoneUtil.find_phone_from_content(content)

          %PostParser{
            content: content,
            url: url,
            phone: phone
          }
        { :error, message } ->
          log_info = "Error PostParser.Dadi.Post HTML parse error, #{message}"
          IO.puts(log_info)
          Logger.error(log_info)
          Efl.Mailer.send_alert(log_info)
          %PostParser{}
      end
    rescue
      ex ->
        IO.puts("Post#parse_post url: #{url}, message: #{inspect(ex)}")
        %PostParser{}
    end
  end
    
  defp html(url) do
    body = Efl.MyHttp.request(url)
    { :ok, body }
  end
end
