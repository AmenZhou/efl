defmodule ClassificationUtility.PageController do
  use ClassificationUtility.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
