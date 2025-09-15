defmodule Efl.LoggerBackend do
  @moduledoc """
  Custom logger backend that writes all application logs to info.log
  """
  
  @behaviour :gen_event
  
  @log_file "info.log"
  
  def init({__MODULE__, name}) do
    {:ok, %{name: name, log_file: @log_file}}
  end
  
  def handle_event({level, _gl, {Logger, msg, ts, md}}, state) do
    # Format the log message
    timestamp = format_timestamp(ts)
    level_str = Atom.to_string(level) |> String.upcase()
    request_id = get_request_id(md)
    
    # Create formatted message
    formatted_msg = "#{timestamp} [#{level_str}] #{request_id} #{msg}\n"
    
    # Write to file
    File.write!(state.log_file, formatted_msg, [:append])
    
    {:ok, state}
  end
  
  def handle_event(_, state) do
    {:ok, state}
  end
  
  def handle_call({:configure, _opts}, state) do
    {:ok, :ok, state}
  end
  
  def handle_info(_, state) do
    {:ok, state}
  end
  
  def terminate(_reason, _state) do
    :ok
  end
  
  defp format_timestamp(_timestamp) do
    # Format timestamp as ISO string
    DateTime.utc_now() |> DateTime.to_string()
  end
  
  defp get_request_id(md) do
    case Keyword.get(md, :request_id) do
      nil -> ""
      request_id -> "#{request_id} "
    end
  end
end
