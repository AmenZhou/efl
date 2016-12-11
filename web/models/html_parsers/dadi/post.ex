defmodule Efl.HtmlParsers.Dadi.Post do
  alias Efl.HtmlParsers.Dadi.Post, as: HtmlParser
  require IEx

  def parse_posts(urls) do
    urls
    |> Enum.map(&parse_post/1)
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
        content = body
                  |> Floki.find(".postbody")
                  |> Floki.text
                  |> String.strip
        %{ content: content, url: url }
      _ ->
        raise "Error HtmlParsers.Dadi.Post HTML parse error"
    end
  end

  defp html(url) do
    case HTTPotion.get(url) do
      %{ body: body } ->
        { :ok, body }
      %{ message: message } ->
        { :error, message }
    end
  end
end
