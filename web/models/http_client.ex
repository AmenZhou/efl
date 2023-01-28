defmodule HttpClient do
  use Tesla

  plug Tesla.Middleware.JSON

  def get(url) do
    get(url)
  end
end
