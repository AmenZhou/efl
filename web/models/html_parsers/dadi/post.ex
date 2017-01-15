defmodule Efl.HtmlParsers.Dadi.Post do
  alias Efl.HtmlParsers.Dadi.Post, as: PostParser
  alias Efl.PhoneUtil
  require IEx
  require Logger

  defstruct [:url, :phone, :content]

  @http_config [
    ibrowse: [proxy_host: '91.73.131.254', proxy_port: 8080],
    timeout: 50_000
  ]
  @http_interval 10_000

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
