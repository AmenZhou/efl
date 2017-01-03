defmodule Efl.Mailer do
  alias Efl.Xls.Dadi, as: Xls

  @config domain: Application.get_env(:mailgun, :mailgun_domain),
          key: Application.get_env(:mailgun, :mailgun_key),
          httpc_opts: [connect_timeout: 2000, timeout: 3000]
  @from "haimeng.zhou@sandboxad2a0aa5c6cc4d52a6029ac88d0bb74f.mailgun.org"

  use Mailgun.Client, @config
  require IEx

  def send_email_with_xls do
    file_name = Xls.file_name

    send_email(to: "chou.amen@gmail.com", #joyce.lei@epochtimes.com",
               from: @from,
               subject: "DADI 360 -- #{file_name}",
               text: "Please see the attachment",
               attachments: [
                 %{
                   path: file_name,
                   filename: file_name,
                 }
                ])
  end
end
