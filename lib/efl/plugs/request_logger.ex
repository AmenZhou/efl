defmodule Efl.Plugs.RequestLogger do
  @moduledoc """
  Plug to log HTTP requests to info.log file
  """
  
  import Plug.Conn
  require Logger
  
  def init(opts), do: opts
  
  def call(conn, _opts) do
    start_time = System.monotonic_time()
    
    register_before_send(conn, fn conn ->
      stop_time = System.monotonic_time()
      diff = System.convert_time_unit(stop_time - start_time, :native, :microsecond)
      
      # Log to both console (via Logger) and file
      message = "#{conn.method} #{conn.request_path} - #{conn.status} (#{format_diff(diff)})"
      
      # Log to console via standard Logger
      Logger.info(message)
      
      # Log to file via our custom logger
      Efl.FileLogger.info(message, request_id: get_request_id(conn))
      
      conn
    end)
  end
  
  defp format_diff(diff) when diff > 1000, do: "#{div(diff, 1000)}ms"
  defp format_diff(diff), do: "#{diff}μs"
  
  defp get_request_id(conn) do
    case get_req_header(conn, "x-request-id") do
      [request_id] -> request_id
      [] -> Logger.metadata()[:request_id] || ""
    end
  end
end
