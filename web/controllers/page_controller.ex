defmodule Efl.PageController do
  use Efl.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
