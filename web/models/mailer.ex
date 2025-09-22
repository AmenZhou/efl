defmodule Efl.Mailer do
  use Swoosh.Mailer, otp_app: :efl
  
  alias Efl.Xls.Dadi, as: Xls
  import Swoosh.Email

  @recipient Application.get_env(:mailgun, :recipient)
  @from "haimeng.zhou@zhouhaimeng.com"
  # @from "haimeng.zhou@sandboxad2a0aa5c6cc4d52a6029ac88d0bb74f.mailgun.org"
  @alert_recipient Application.get_env(:mailgun, :alert_recipient)

  require IEx
  require Logger

  def send_email_with_xls do
    file_name = Xls.file_name
    
    # Check if file exists and has content
    if File.exists?(file_name) do
      file_size = File.stat!(file_name).size
      
      if file_size > 1000 do  # More than just headers
        email = new()
        |> to(@recipient)
        |> from(@from)
        |> subject("DADI 360 -- #{file_name}")
        |> text_body("Please see the attachment")
        |> attachment(%Swoosh.Attachment{
          path: file_name,
          filename: file_name,
          content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        })
        
        case deliver(email) do
          {:error, _} -> send_alert()
          {:ok, success} -> success
        end
      else
        Logger.warning("Excel file is too small (#{file_size} bytes) - skipping email send")
        send_alert("Excel file is empty or too small (#{file_size} bytes)")
      end
    else
      Logger.error("Excel file does not exist: #{file_name}")
      send_alert("Excel file does not exist: #{file_name}")
    end
  end

  def send_alert do
    email = new()
    |> to(@alert_recipient)
    |> from(@from)
    |> subject("Alert! The excel file #{Xls.file_name} wasn't sent out successfully")
    |> text_body("Please contact admin, email: chou.amen@gmail.com")
    
    deliver(email)
  end

  def send_alert(message) do
    email = new()
    |> to(@alert_recipient)
    |> from(@from)
    |> subject("Alert! A system exception occurred.")
    |> text_body("Please contact admin, email: chou.amen@gmail.com.\n\rDetail: #{message}.")
    
    deliver(email)
  end
end
