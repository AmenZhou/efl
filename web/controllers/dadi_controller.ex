defmodule Efl.DadiController do
  use Efl.Web, :controller
  alias Efl.Repo
  alias Efl.Dadi
  require IEx

  def index(conn, _params) do
    posts = Dadi |> Repo.all
    render conn, "index.html", %{posts: posts}
  end

  def scratch(conn, _params) do
    ip_addr = to_string(:inet_parse.ntoa(conn.remote_ip))
    if ip_addr == "127.0.0.1" do
      Efl.Dadi.start
      text conn, "Start scratching DD360..."
    else
      text conn, "No permission"
    end
  end
end
