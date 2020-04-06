defmodule Efl.MyHttp do
  require IEx
  alias Efl.Proxy

  def request(url, attempts \\ 1) do
    proxy = case attempts do 
      4 ->
        Proxy.fetch_proxy(true)
      7 ->
        raise("Has reached the max attempts of fetching category page, #{url}")
      _ ->
        Proxy.fetch_proxy()
    end

    case HTTPotion.get(url, proxy_config(proxy)) do
      %{ body: body } ->
        IO.puts("Fetch a cateogry page successfully, #{url}")
        body
      %{ message: message } ->
        IO.puts("Fetch category fail, #{url}, #{message}")
        IO.puts("Retry... #{attempts+1} attempts")
        request(url, attempts + 1)
    end
  end

  def proxy_config(proxy) do
    %{ ip: ip, port: port } = proxy
    [ ibrowse: [ proxy_host: ip, proxy_port: port ], timeout: 30_000 ]
  end
end