defmodule Efl.DadiController do
  use Efl.Web, :controller
  alias Efl.Repo
  alias Efl.Dadi

  def index(conn, _params) do
    posts = Dadi |> Repo.all
    render conn, "index.html", %{posts: posts}
  end
end
