defmodule Efl.HtmlParsers.Dadi.Post do
  alias Efl.HtmlParsers.Dadi.Post, as: PostParser
  alias Efl.PhoneUtil
  require IEx
  require Logger

  defstruct [:url, :phone, :content]

  def parse_post(url) do
    try do
      case html(url) do
        { :ok, body } ->
          Logger.info("Post parsed one url: #{url}")
          content = body
                    |> Floki.find(".postbody")
                    |> Floki.text
                    |> String.strip

          phone = PhoneUtil.find_phone_from_content(content)

          %PostParser{
            content: content,
            url: url,
            phone: phone
          }
        { :error, message } ->
          log_info = "Error PostParser.Dadi.Post HTML parse error, #{message}"
          Logger.error(log_info)
          Efl.Mailer.send_alert(log_info)
          %PostParser{}
      end
    rescue
      ex ->
        log_info = "Post#parse_post url: #{url}, message: #{inspect(ex)}"
        Logger.error(log_info)
        Efl.Mailer.send_alert(log_info)
        %PostParser{}
    end
  end

  defp html(url) do
    body = Efl.MyHttp.request(url)
    { :ok, body }
  end
end
