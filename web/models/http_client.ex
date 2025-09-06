defmodule HttpClient do
  use Tesla
  @timeout 120_000
  plug Tesla.Middleware.JSON

  def get(url, proxy) do
    get(url, opts: [adapter: [proxy: proxy_config(proxy), recv_timeout: @timeout]])
  end

  def post(url, body, opts \\ []) do
    Tesla.post(url, body, opts)
  end

  defp proxy_config(proxy) do
    %{ ip: ip, port: port } = proxy
    { ip, port }
  end
end
