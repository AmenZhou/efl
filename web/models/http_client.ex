defmodule HttpClient do
  use Tesla
  @timeout 120_000
  plug Tesla.Middleware.JSON
  # Site redirects HTTP → HTTPS; follow so we get the real page (and body with dadiicon.ico).
  plug Tesla.Middleware.FollowRedirects, max_redirects: 5
  # Browser-like User-Agent so c.dadi360.com is less likely to return 400/405 (many sites block missing or bot User-Agents).
  plug Tesla.Middleware.Headers, [
    {"user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"},
    {"accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"},
    {"accept-language", "en-US,en;q=0.9"}
  ]

  def get(url, proxy) do
    # TLS verification: default verify_none when using proxies (set HTTP_SSL_VERIFY=true to enable). See documents/proxy_vs_target.md.
    ssl_verify = System.get_env("HTTP_SSL_VERIFY") == "true" or System.get_env("HTTP_SSL_VERIFY") == "1"
    ssl_opt = if ssl_verify, do: [], else: [ssl: {:verify, :verify_none}]
    get(url, opts: [adapter: [proxy: proxy_config(proxy), recv_timeout: @timeout] ++ ssl_opt])
  end

  def post(url, body, opts \\ []) do
    Tesla.post(url, body, opts)
  end

  defp proxy_config(proxy) do
    %{ ip: ip, port: port } = proxy
    { ip, port }
  end
end
