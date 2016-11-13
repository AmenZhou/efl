defmodule ClassificationUtility.DadiPost do
  def parse_posts(urls) do
    urls
    |> Enum.map(&parse_post/1)
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
