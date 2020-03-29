defmodule Efl.MyHttp do
  require IEx
  alias Efl.Proxy

  def request(url) do
    try do
      proxy = Proxy.fetch_proxy()
      IO.inspect(proxy_config(proxy))
      case HTTPotion.get(url, proxy_config(proxy)) do
        %{ body: body } ->
          IO.puts("Fetch a page successfully")
          IO.puts(url)
          body
        %{ message: message } ->
          IO.puts("Fetch category fail, #{url}, #{message}")
          handle_failure(url)
      end
    rescue
      ex ->
        IO.puts("Fetch category Exception!!, #{url}")
        IO.inspect(ex)
        handle_failure(url)
    end
  end

  def proxy_config(proxy) do
    %{ ip: ip, port: port } = proxy
    [ ibrowse: [ proxy_host: ip, proxy_port: port ], timeout: 150_000 ]
  end

  def handle_failure(url) do
    IO.puts("Refetch proxy and try again...")
    proxy = Proxy.fetch_proxy(true)
    case HTTPotion.get(url, proxy_config(proxy)) do
      %{ body: body } ->
        IO.puts("Refetch a page successfully")
        IO.puts(url)
        body
      %{ message: message } ->
        IO.puts("Refetch category fail, #{url}, #{message}")
        raise("Fetch category fail, #{url}, #{message}")
    end
  end
end