defmodule ClassificationUtility.Dadi.Post do
  alias ClassificationUtility.Dadi.Post

  def parse_posts(urls) do
    urls
    |> Enum.map(&parse_post/1)
  end

  def async_parse_posts(urls) do
    tasks = urls
            |> Enum.map(fn(url) ->
              :timer.sleep(100)
              Task.async(Post, :parse_post, [url])
            end)

    tasks
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
        %{ content: content }
    end
  end

  def html(url) do
    case HTTPotion.get(url) do
      %{ body: body } ->
        { :ok, body }
      %{ message: message } ->
        { :error, message }
    end
  end
end
