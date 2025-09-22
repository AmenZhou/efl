defmodule Efl.DevHttp do
  @moduledoc """
  Development HTTP client that bypasses proxy requirements for local testing.
  This module provides a simplified HTTP client for development environments
  where proxy rotation is not needed or available.
  """
  
  require Logger
  use Tesla

  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.FollowRedirects, max_redirects: 3
  plug Tesla.Middleware.Timeout, timeout: 30_000

  @doc """
  Makes a simple HTTP GET request without proxy requirements.
  Used in development environment when proxy system is not available.
  """
  def get(url) do
    Logger.info("DevHttp: Making request to #{url}")
    
    case Tesla.get(url) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        Logger.info("DevHttp: Successfully fetched #{url} (status: #{status})")
        {:ok, body}
      
      {:ok, %{status: status, body: body}} ->
        Logger.warning("DevHttp: HTTP error #{status} for #{url}")
        {:error, "HTTP #{status}: #{String.slice(to_string(body), 0, 200)}"}
      
      {:error, reason} ->
        Logger.error("DevHttp: Request failed for #{url}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Makes a simple HTTP POST request without proxy requirements.
  """
  def post(url, body, opts \\ []) do
    Logger.info("DevHttp: Making POST request to #{url}")
    
    case Tesla.post(url, body, opts) do
      {:ok, %{status: status, body: response_body}} when status in 200..299 ->
        Logger.info("DevHttp: Successfully posted to #{url} (status: #{status})")
        {:ok, response_body}
      
      {:ok, %{status: status, body: response_body}} ->
        Logger.warning("DevHttp: HTTP error #{status} for POST #{url}")
        {:error, "HTTP #{status}: #{String.slice(to_string(response_body), 0, 200)}"}
      
      {:error, reason} ->
        Logger.error("DevHttp: POST request failed for #{url}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Validates that the response contains expected content.
  This is a simplified version of the proxy validation logic.
  """
  def validate_response(body, url) do
    if String.contains?(body, "/img/dadiicon.ico") do
      Logger.info("DevHttp: Response validation passed for #{url}")
      true
    else
      Logger.warning("DevHttp: Response validation failed for #{url} - missing expected content")
      false
    end
  end
end
