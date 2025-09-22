defmodule Efl.HtmlParsers.Dadi.Category do
  alias Efl.RefCategory
  alias Efl.PhoneUtil
  alias Efl.HtmlParsers.Dadi.Category, as: CategoryParser
  require IEx
  require Logger

  defstruct [:title, :url, :post_date, :phone, :ref_category_id]

  #Don't add / at the tail of the url
  @base_url "http://c.dadi360.com"
  @http_interval 1_000

  #The returned value should be [{ :ok, %Dadi{} }, ...]
  def parse(ref_category) do
    raw_items(ref_category)
    |> Enum.map(&parse_one_page/1)
    |> Enum.concat
  end

  def parse_one_page(html_items) do
    :timer.sleep(@http_interval)
    try do
      case html_items do
        { :ok, items } ->
          Logger.info("Category has parsed one page")
          Enum.map(items, fn(item) ->
            item
            |> dadi_params
          end)
        { :error, message } ->
          Logger.error(message)
          Efl.Mailer.send_alert(message)
          []
      end
    rescue
      ex ->
        Logger.error("Error HtmlParser.Dadi.Category, #{inspect(ex)}")
        ex |> inspect |> Efl.Mailer.send_alert()
        []
    end
  end

  #Return a List of raw items
  #The returned value should be [{ :ok, [item1, item2, ...]}, { :ok, [item3, ...]}]
  def raw_items(ref_category) do
    ref_category
    |> RefCategory.get_urls
    |> Enum.map(fn(url) ->
      try do
        body = url |> html
        case body |> find_raw_items do
          { :ok, items } ->
            if Enum.empty?(items) do
              IO.inspect(body)
              Logger.info("raw_items - Get empty items")
            end
            { :ok, items }
          _ ->
            raise("raw_items - Fail to get items")
        end
      rescue
        ex ->
          Logger.error("Fail at Category#raw_items url: #{url}, message: #{inspect(ex)}")
          { :error, "Fail at Category#raw_items url: #{url}, message: #{inspect(ex)}" }
      end
    end)
  end

  defp dadi_params(item) do
    title = get_title(item)
    post_date = get_date(item)
    Logger.info("dadi_params: title=#{title}, post_date=#{inspect(post_date)}")
    %CategoryParser{
      title: title,
      url: @base_url <> get_link(item),
      post_date: post_date,
      phone: PhoneUtil.find_phone_from_content(title)
    }
  end

  defp html(url) do
    body = case Mix.env() do
      :dev -> Efl.DevMyHttp.request(url)
      _ -> Efl.MyHttp.request(url)
    end
    { :ok, body }
  end

  def find_raw_items(html) do
    case html do
      { :ok, html_body } when html_body != nil ->
        #se Try Floki first
        case Floki.parse_document(html_body) do
          { :ok, parsed_doc } ->
            floki_items = Floki.find(".bg_small_yellow", parsed_doc)
            if length(floki_items) > 0 do
              { :ok, floki_items }
            else
              # Fallback to regex if Floki finds nothing
              Logger.warning("Floki found 0 items, falling back to regex extraction")
              regex_items = extract_items_with_regex(html_body)
              { :ok, regex_items }
            end
          { :error, reason } ->
            Logger.error("Floki parse_document failed: #{inspect(reason)}")
            # Fallback to regex
            regex_items = extract_items_with_regex(html_body)
            { :ok, regex_items }
        end
      { :ok, nil } ->
        { :ok, [] }
      _ ->
        raise("Cateogry#find_raw_items Fail")
    end
  end

  # Fallback regex extraction method
  defp extract_items_with_regex(html_body) do
    # Extract all bg_small_yellow rows using regex
    Regex.scan(~r/<tr class="bg_small_yellow">.*?<\/tr>/s, html_body)
    |> Enum.map(fn [match] -> match end)
  end

  def get_title(item) do
    try do
      if is_binary(item) do
        # Handle regex-extracted string
        extract_title_with_regex(item)
      else
        # Handle Floki element - try multiple selectors for nested structure
        title = case Floki.find(".topictitle a span", item) do
          [] ->
            # Try without span
            Floki.find(".topictitle a", item)
            |> Floki.text
            |> String.trim
          spans ->
            spans
            |> List.first
            |> Floki.text
            |> String.trim
        end
        
        # If still no title found, try alternative selectors
        if title == "" do
          Floki.find(".topictitle", item)
          |> Floki.text
          |> String.trim
        else
          Logger.info("Extracted title with Floki: '#{title}'")
          title
        end
      end
    rescue
      ex ->
        Logger.warning("Failed to extract title from item: #{inspect(ex)}")
        ""
    end
  end

  def get_link(item) do
    try do
      if is_binary(item) do
        # Handle regex-extracted string
        extract_link_with_regex(item)
      else
        # Handle Floki element
        Floki.find(".topictitle a", item)
        |> Floki.attribute("href")
        |> List.first
        |> String.split(";")
        |> List.first
      end
    rescue
      ex ->
        Logger.warning("Failed to extract link from item: #{inspect(ex)}")
        ""
    end
  end

  def get_date(item) do
    case item |> parse_date do
      { :ok, date } ->
        # Convert to Date struct if it's a DateTime
        case date do
          %Date{} -> date
          %DateTime{} -> DateTime.to_date(date)
          %NaiveDateTime{} -> NaiveDateTime.to_date(date)
          _ -> date
        end
      { :error, _ } ->
        nil
    end
  end

  def parse_date(item) do
    try do
      date_text = if is_binary(item) do
        # Handle regex-extracted string
        extract_date_with_regex(item)
      else
        # Handle Floki element - try multiple selectors
        case Floki.find(".postdetails", item) do
          [] ->
            # Try alternative selectors
            case Floki.find("td.row3 span.postdetails", item) do
              [] -> ""
              elements -> 
                elements
                |> List.last
                |> Floki.text
                |> String.trim
            end
          elements ->
            elements
            |> List.last
            |> Floki.text
            |> String.trim
        end
      end
      
      Logger.info("Extracted date text: '#{date_text}'")
      
      # Try multiple date formats
      result = parse_date_with_formats(date_text)
      
      case result do
        {:ok, date} -> 
          Logger.info("Successfully parsed date: #{inspect(date)}")
          result
        {:error, reason} -> 
          Logger.warning("Failed to parse date '#{date_text}': #{reason}")
          result
      end
    rescue
      ex ->
        Logger.warning("Failed to parse date from item: #{inspect(ex)}")
        { :error, "Failed to parse date: #{inspect(ex)}" }
    end
  end

  defp parse_date_with_formats(date_text) when is_binary(date_text) and date_text != "" do
    # Try different date formats in order of preference
    formats = [
      {"%m/%d/%Y", :strftime},  # Month/Day/Year (e.g., 9/16/2025)
      {"%m/%e/%Y", :strftime},  # Month/Day (space-padded)/Year
      {"%e/%d/%Y", :strftime},  # Month (space-padded)/Day/Year  
      {"%Y-%m-%d", :strftime},  # ISO format
      {"%d/%m/%Y", :strftime}   # European format (Day/Month/Year)
    ]
    
    # Manual parsing for MM/DD/YYYY format since Timex seems to have issues
    case Regex.run(~r/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/, date_text) do
      [_, month_str, day_str, year_str] ->
        try do
          month = String.to_integer(month_str)
          day = String.to_integer(day_str) 
          year = String.to_integer(year_str)
          
          # Validate date components
          if month >= 1 and month <= 12 and day >= 1 and day <= 31 and year > 1900 do
            case Date.new(year, month, day) do
              {:ok, date} -> {:ok, date}
              {:error, reason} -> {:error, "Invalid date components: #{reason}"}
            end
          else
            {:error, "Invalid date range: #{date_text}"}
          end
        rescue
          _ -> {:error, "Failed to parse date components: #{date_text}"}
        end
      _ ->
        # Fallback to Timex for other formats
        Enum.find_value(formats, fn {format, type} ->
          case Timex.parse(date_text, format, type) do
            {:ok, date} -> {:ok, date}
            {:error, _} -> nil
          end
        end) || {:error, "No valid date format found for: #{date_text}"}
    end
  end

  defp parse_date_with_formats(_), do: {:error, "Empty or invalid date text"}

  # Regex extraction helpers
  defp extract_title_with_regex(html_string) do
    # Try the correct pattern based on actual HTML structure
    case Regex.run(~r/<span class="topictitle">.*?<span[^>]*>\s*([^<]+?)\s*<\/span>/s, html_string) do
      [_, title] -> 
        title = String.trim(title)
        Logger.info("Extracted title with regex: '#{title}'")
        title
      _ -> 
        # Fallback: try simpler pattern
        case Regex.run(~r/<span class="topictitle">.*?<a[^>]*>.*?<span[^>]*>([^<]+?)<\/span>/s, html_string) do
          [_, title] -> 
            title = String.trim(title)
            Logger.info("Extracted title with fallback regex: '#{title}'")
            title
          _ -> 
            Logger.warning("Failed to extract title with regex from: #{String.slice(html_string, 0, 200)}...")
            ""
        end
    end
  end

  defp extract_link_with_regex(html_string) do
    case Regex.run(~r/<a href="([^"]+)">/s, html_string) do
      [_, link] -> 
        link
        |> String.split(";")
        |> List.first
      _ -> ""
    end
  end

  defp extract_date_with_regex(html_string) do
    # Find date in span with class="postdetails" - support both 1-digit and 2-digit formats
    case Regex.run(~r/<span class="postdetails">\s*(\d{1,2}\/\d{1,2}\/\d{4})\s*<\/span>/s, html_string) do
      [_, date] -> 
        date = String.trim(date)
        Logger.info("Extracted date with regex: '#{date}'")
        date
      _ -> 
        # Fallback: try to find date in any element with class="postdetails"
        case Regex.run(~r/class="postdetails"[^>]*>\s*(\d{1,2}\/\d{1,2}\/\d{4})\s*</s, html_string) do
          [_, date] -> 
            date = String.trim(date)
            Logger.info("Extracted date with fallback regex: '#{date}'")
            date
          _ -> 
            Logger.warning("Failed to extract date with regex from: #{String.slice(html_string, 0, 200)}...")
            ""
        end
    end
  end
end
