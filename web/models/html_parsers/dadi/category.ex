defmodule Efl.HtmlParsers.Dadi.Category do 
  alias Efl.RefCategory
  alias Efl.PhoneUtil
  alias Efl.HtmlParsers.Dadi.Category, as: CategoryParser
  require IEx

  defstruct [:title, :url, :post_date, :phone, :ref_category_id]

  #Don't add / at the tail of the url
  @base_url "http://googleweblight.com/?lite_url=http://c.dadi360.com"
  @http_config [
    ibrowse: [proxy_host: '91.73.131.254', proxy_port: 8080],
    timeout: 50_000
  ]
  @http_interval 10_000

  #The returned value should be [{ :ok, %Dadi{} }, ...]
  def parse(ref_category) do
    raw_items(ref_category)
    |> Enum.map(&parse_one_page/1)
    |> Enum.concat
  end

  def parse_one_page(html_items) do
    :timer.sleep(@http_interval)
    case html_items do
      { :ok, items } ->
        IO.puts("Category has parsed one page")
        categories = Enum.map(items, fn(item) ->
          item
          |> dadi_params
        end)
        categories
      { :error, message } ->
        IO.puts("Error HtmlParsers.Dadi.Category HTML parse error: #{message}")
    end
  end

  #Return a List of raw items
  #The returned value should be [{ :ok, [item1, item2, ...]}, { :ok, [item3, ...]}]
  def raw_items(ref_category) do
    ref_category
    |> RefCategory.get_urls
    |> Enum.map(fn(url) ->
      url
      |> html
      |> find_raw_items
    end)
  end

  defp dadi_params(item) do
    title = get_title(item)
    %CategoryParser{
      title: title,
      url: @base_url <> get_link(item),
      post_date: get_date(item),
      phone: PhoneUtil.find_phone_from_content(title)
    }
  end

  defp html(url) do
    case HTTPotion.get(url, @http_config) do
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
end
