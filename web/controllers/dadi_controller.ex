defmodule Efl.DadiController do
  use Efl.Web, :controller
  alias Efl.Repo
  alias Efl.Dadi
  alias Efl.Mailer

  def index(conn, _params) do
    posts = Dadi |> Repo.all
    render conn, "index.html", %{posts: posts}
  end

  def scratch(conn, _params) do
    Efl.Dadi.start
    ip_addr = to_string(:inet_parse.ntoa(conn.remote_ip))
    Mailer.send_alert("IP address: #{ip_addr}")
    text conn, "Start scratching DD360..."
  end
end
