defmodule Efl.DevMyHttp do
  @moduledoc """
  Development version of MyHttp that uses DevHttp instead of proxy rotation.
  This module provides the same interface as MyHttp but works in development
  environments where proxy systems may not be available.
  """
  
  require Logger
  alias Efl.DevHttp

  @max_attempt 10  # Reduced for dev environment
  @request_interval 2_000  # Increased interval for dev

  def request(url, attempts \\ 1)

  def request(url, attempts) when attempts >= @max_attempt do
    Logger.error("DevMyHttp: Max attempts reached for #{url}")
    raise("Has reached the max attempts of fetching page, #{url}")
  end

  def request(url, attempts) do
    Logger.info("DevMyHttp: Attempt #{attempts} for #{url}")
    
    # Add delay between requests
    if attempts > 1 do
      :timer.sleep(@request_interval)
    end

    case DevHttp.get(url) do
      {:ok, body} ->
        if DevHttp.validate_response(body, url) do
          Logger.info("DevMyHttp: Successfully fetched #{url}")
          body
        else
          Logger.warning("DevMyHttp: Response validation failed for #{url}, retrying...")
          request(url, attempts + 1)
        end
      
      {:error, reason} ->
        Logger.warning("DevMyHttp: Request failed for #{url}: #{inspect(reason)}, retrying...")
        request(url, attempts + 1)
    end
  end

  @doc """
  Returns empty list for dev environment (no proxy management needed).
  """
  def number_of_proxies_needed do
    []
  end
end
