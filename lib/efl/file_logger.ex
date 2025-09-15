defmodule Efl.FileLogger do
  @moduledoc """
  Simple file logger that writes logs to info.log
  """
  
  @log_file "info.log"
  
  def log(level, message, metadata \\ []) do
    timestamp = DateTime.utc_now() |> DateTime.to_string()
    request_id = Keyword.get(metadata, :request_id, "")
    
    formatted_message = "#{timestamp} [#{level}] #{request_id} #{message}\n"
    
    File.write!(@log_file, formatted_message, [:append])
  end
  
  def info(message, metadata \\ []) do
    log(:info, message, metadata)
  end
  
  def warn(message, metadata \\ []) do
    log(:warn, message, metadata)
  end
  
  def error(message, metadata \\ []) do
    log(:error, message, metadata)
  end
  
  def debug(message, metadata \\ []) do
    log(:debug, message, metadata)
  end
end
