defmodule ClassificationUtility.DadiController do
  use ClassificationUtility.Web, :controller
  alias ClassificationUtility.Repo
  alias ClassificationUtility.Dadi.Main, as: Dadi

  def index(conn, _params) do
    posts = Dadi |> Repo.all
    render conn, "index.html", %{posts: posts}
  end
end
