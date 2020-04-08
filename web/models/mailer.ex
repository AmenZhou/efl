defmodule Efl.Mailer do
  alias Efl.Xls.Dadi, as: Xls

  @config domain: Application.get_env(:mailgun, :mailgun_domain),
          key: Application.get_env(:mailgun, :mailgun_key),
          httpc_opts: [connect_timeout: 2000, timeout: 3000]
  @recipient Application.get_env(:mailgun, :recipient)
  @from "haimeng.zhou@zhouhaimeng.com"
  # @from "haimeng.zhou@sandboxad2a0aa5c6cc4d52a6029ac88d0bb74f.mailgun.org"
  @alert_recipient Application.get_env(:mailgun, :alert_recipient)

  use Mailgun.Client, @config
  require IEx

  def send_email_with_xls do
    file_name = Xls.file_name

    response = send_email(
                          to: @recipient,
                          from: @from,
                          subject: "DADI 360 -- #{file_name}",
                          text: "Please see the attachment",
                          attachments: [
                            %{
                              path: file_name,
                              filename: file_name,
                            }
    ])

    case response do
      {:error, msg} -> send_alert
      {:ok, sucess} -> sucess
    end
  end

  def send_alert do
    send_email(
               to: @alert_recipient,
               from: @from,
               subject: "Alert! The excel file #{Xls.file_name} wasn't sent out successfully",
               text: "Please contact admin, email: chou.amen@gmail.com"
              )
  end

  def send_alert(message) do
    send_email(
               to: @alert_recipient,
               from: @from,
               subject: "Alert! A system exception occurred.",
               text: "Please contact admin, email: chou.amen@gmail.com.\n\rDetail: #{message}."
              )
  end
end
