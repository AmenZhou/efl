defmodule Efl.MyHttp do
  require IEx
  alias Efl.Proxy

  def request(url, attempts \\ 1) do
    proxy = case attempts do 
      3 ->
        Proxy.fetch_proxy(true)
      6 ->
        Proxy.fetch_proxy(true)
      9 ->
        Proxy.fetch_proxy(true)
      12 ->
        Proxy.fetch_proxy(true)
        raise("Has reached the max attempts of fetching category page, #{url}")
      _ ->
        Proxy.fetch_proxy()
    end

    case HTTPotion.get(url, proxy_config(proxy)) do
      %{ body: body } ->
        if String.match?(body, ~r/Unable to complete URL request</) do
          IO.puts("Fetch category fail, #{url}, no access")
          request(url, attempts + 1)
        end
        IO.puts("Fetch a cateogry page successfully, #{url}")
      %{ message: message } ->
        IO.puts("Fetch category fail, #{url}, #{message}")
        IO.puts("Retry... #{attempts+1} attempts")
        request(url, attempts + 1)
    end
  end

  def proxy_config(proxy) do
    %{ ip: ip, port: port } = proxy
    [ ibrowse: [ proxy_host: ip, proxy_port: port ], timeout: 60_000 ]
    # [ ibrowse: [ proxy_host: '70.110.31.20', proxy_port: 8080 ], timeout: 60_000 ]
  end
end