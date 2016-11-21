defmodule ClassificationUtility.Dadi.Category do
  require IEx

  alias ClassificationUtility.Repo
  alias ClassificationUtility.Dadi.Main

  @base_url "http://c.dadi360.com/"

  def parse_and_return_post_urls(url) do
    items = parse_items(url)
    case items do
      { :error, message } -> { :error, message }
      { :ok, items } ->
        Enum.map(items, fn(item) ->
          case item do
            { :ok, item } ->
              item
              |> Map.get(:url)
            { :error, message } ->
              IO.puts message
          end
        end)
    end
  end

  #[{ :ok, %Dadi{}}, { :ok, %Dadi{} }, ...]
  def parse_items(ref_category) do
    ref_category
    |> raw_items
    |> Enum.map(fn(items) -> parse_item(items) end)
    |> Enum.concat
  end

  #The returned value should be [{ :ok, %Dadi{} }, ...]
  def parse_item(item) do
    case item do
      { :ok, items } ->
        categories = Enum.map(items, fn(item) ->
          item
          |> dadi_params
          |> Map.merge(%{ ref_category_id: ref_category_id })
          |> insert
        end)
        { :ok, categories }
      { :error, message } ->
        { :error, message }
    end
  end

  def dadi_params(item) do
    %{
      title: get_title(item),
      url: @base_url <> get_link(item),
      post_date: get_date(item)
    }
  end

  def insert(item) do
    set = Main.changeset(%Dadi{}, item)
    Repo.insert(set)
  end

  defp html(url) do
    case HTTPotion.get(url) do
      %{ body: body } ->
        { :ok, body }
      %{ message: message } ->
        { :error, message }
    end
  end

  defp find_raw_items(html) do
    case html do
      { :ok, html_body } ->
        { :ok,
          html_body
          |> Floki.parse
          |> Floki.find(".bg_small_yellow")
        }
      _ ->
        html
    end
  end

  defp get_title(item) do
    item
    |> Floki.find(".topictitle a")
    |> Floki.text
    |> String.strip
  end

  defp get_link(item) do
    item
    |> Floki.find(".topictitle a")
    |> Floki.attribute("href")
    |> List.first
    |> String.split(";")
    |> List.first
  end

  defp get_date(item) do
    case item |> parse_date do
      { :ok, date } ->
        date
      { :error, _ } ->
        nil
    end
  end

  defp parse_date(item) do
    item
    |> Floki.find(".postdetails")
    |> List.last
    |> Floki.text
    |> String.strip
    |> Timex.parse("%Y/%_m/%e", :strftime)
  end

  #Return a List of raw items
  #The returned value should be [{ :ok, [item1, item2, ...]}, { :ok, [item3, ...]}]
  defp raw_items(ref_category) do
    ref_category
    |> RefCategory.get_urls
    |> Enum.map(fn(url) ->
      url
      |> html
      |> find_raw_items
    end)
  end
end
