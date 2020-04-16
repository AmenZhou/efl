defmodule Efl.MyHttp do
  require IEx
  require Logger
  alias Efl.Proxy

  def request(url, attempts \\ 1) do
    if attempts >= 12 do
      Proxy.fetch_proxy(true)
      raise("Has reached the max attempts of fetching category page, #{url}")
    end

    # Fetch proxy after 3 retries
    proxy = case Integer.mod(attempts, 3) do 
      0 ->
        Proxy.fetch_proxy(true)
      _ ->
        Proxy.fetch_proxy()
    end

    case HTTPotion.get(url, proxy_config(proxy)) do
      %{ body: body } ->
        if !String.match?(body, ~r/www.dadi360.com\/img\/dadiicon.ico/) do
          Log.info("Fetch fail, #{url}, NO ACCESS")
          Log.info("Retry... #{attempts+1} attempts")
          request(url, attempts + 1)
        else
          Log.info("Fetch a cateogry page successfully, #{url}")
          body
        end
      %{ message: message } ->
        Log.info("Fetch fail, #{url}, #{message}")
        Log.info("Retry... #{attempts+1} attempts")
        request(url, attempts + 1)
    end
  end

  def proxy_config(proxy) do
    %{ ip: ip, port: port } = proxy
    [ ibrowse: [ proxy_host: ip, proxy_port: port ], timeout: 60_000 ]
  end
end