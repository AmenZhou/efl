defmodule ClassificationUtility.DadiCategory do
  @base_url "http://c.dadi360.com"
  require IEx

  def parse_items(url) do
    Enum.map(html(url) |> items, &parse_item/1)
  end

  def parse_item(item) do
    %{ title: get_title(item), url: @base_url <> get_link(item)}
  end

  def html(url) do
    case HTTPotion.get(url) do
      %{ body: body } ->
        { :ok, body }
      %{ message: message } ->
        { :error, message }
    end
  end

  def items(html) do
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
    |> List.first
  end
end
