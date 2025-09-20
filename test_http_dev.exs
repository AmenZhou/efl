#!/usr/bin/env elixir

# Test script to verify HTTP requests work in Docker dev environment
# Run with: elixir test_http_dev.exs

defmodule TestHttpDev do
  def test_http_requests do
    IO.puts("Testing HTTP requests in development environment...")
    IO.puts("=" <> String.duplicate("=", 50))
    
    # Test basic HTTP request
    test_url = "https://httpbin.org/get"
    IO.puts("Testing basic HTTP request to #{test_url}")
    
    case make_request(test_url) do
      {:ok, body} ->
        IO.puts("✅ Basic HTTP request successful")
        IO.puts("Response length: #{String.length(body)} characters")
        IO.puts("Response preview: #{String.slice(body, 0, 200)}...")
      {:error, reason} ->
        IO.puts("❌ Basic HTTP request failed: #{inspect(reason)}")
    end
    
    IO.puts("")
    
    # Test target website (if accessible)
    test_dadi_url = "http://c.dadi360.com/c/forums/show/80/1.page"
    IO.puts("Testing DADI website request to #{test_dadi_url}")
    
    case make_request(test_dadi_url) do
      {:ok, body} ->
        IO.puts("✅ DADI website request successful")
        IO.puts("Response length: #{String.length(body)} characters")
        
        # Check for expected content
        if String.contains?(body, "dadiicon.ico") do
          IO.puts("✅ Response contains expected content (dadiicon.ico)")
        else
          IO.puts("⚠️  Response does not contain expected content")
        end
        
        IO.puts("Response preview: #{String.slice(body, 0, 200)}...")
      {:error, reason} ->
        IO.puts("❌ DADI website request failed: #{inspect(reason)}")
    end
    
    IO.puts("")
    IO.puts("HTTP request testing completed.")
  end
  
  defp make_request(url) do
    try do
      case System.cmd("curl", ["-s", "-L", "--max-time", "30", url]) do
        {body, 0} when body != "" ->
          {:ok, body}
        {error, _} ->
          {:error, "Curl failed: #{error}"}
      end
    rescue
      e ->
        {:error, "Exception: #{inspect(e)}"}
    end
  end
end

TestHttpDev.test_http_requests()
