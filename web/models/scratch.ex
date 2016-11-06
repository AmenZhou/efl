defmodule ClassificationUtility.Scratch do
  def parse_items do
    Enum.each(items, &parse_item/1)
  end

  def parse_item(item) do
    IO.puts "Title: "
    get_title(item) |> IO.puts
    IO.puts "Link: "
    get_link(item) |> IO.puts
  end

  def html do
    case HTTPotion.get(url) do
      %{ body: body } ->
        { :ok, body }
      %{ message: message } ->
        { :error, message }
    end
  end

  def url do
    "http://c.dadi360.com/c/forums/show/53.page"
  end

  def items do
    case html do
      { :ok, html_body } ->
        html_body |> Floki.parse |> Floki.find(".bg_small_yellow")
      { :error, message } ->
        message
    end
  end

  def get_title(item) do
    item
    |> Floki.find(".topictitle a")
    |> Floki.text
    |> String.strip
  end

  def get_link(item) do
    item
    |> Floki.find(".topictitle a")
    |> Floki.attribute("href")
  end
end
