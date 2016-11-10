defmodule ClassificationUtility.DadiCategory do
  require IEx

  alias ClassificationUtility.Repo
  alias ClassificationUtility.Dadi

  @base_url "http://c.dadi360.com"

  def parse_items(url) do
    Enum.map(html(url) |> find_raw_items, fn(item) ->
      item
      |> parsed_item
      |> insert
    end)
  end

  def parsed_item(item) do
    %{
      title: get_title(item),
      url: @base_url <> get_link(item),
      post_date: get_date(item)
    }
  end

  def insert(item) do
    IO.inspect item
    #set = Dadi.changeset(%Dadi{}, item)
    #post_url = item |> Map.get(:url)

    #case Repo.insert(set) do
      #{ :ok, _ } ->
        #{ :ok, %{ url: post_url } }
      #{ :error, _ } ->
        #{ :error, "Create Dadi Error url #{post_url}" }
    #end
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
        html_body |> Floki.parse |> Floki.find(".bg_small_yellow")
      { :error, message } ->
        message
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
    item
    |> Floki.find(".postdetails")
    |> Floki.text
    |> String.strip
    |> String.slice(3..-1)
    |> Timex.parse("%Y/%_m/%e", :strftime)
  end
end
