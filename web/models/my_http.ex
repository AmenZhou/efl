defmodule Efl.MyHttp do
  require IEx
  require Logger
  alias Efl.Proxy
  @timeout 120_000
  @max_attempt 12

  def request(url, attempts \\ 1)
  def request(url, attempts) when attempts < @max_attempt do
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
          Logger.info("Fetch fail, #{url}, NO ACCESS")
          Logger.info("Retry... #{attempts+1} attempts")
          request(url, attempts + 1)
        else
          Logger.info("Fetch a cateogry page successfully, #{url}")
          body
        end
      %{ message: message } ->
        Logger.info("Fetch fail, #{url}, #{message}")
        Logger.info("Retry... #{attempts+1} attempts")
        request(url, attempts + 1)
    end
  end

  def request(url, attempts) when attempts >= @max_attempt do
    Proxy.fetch_proxy(true)
    raise("Has reached the max attempts of fetching category page, #{url}")
  end

  def proxy_config(proxy) do
    %{ ip: ip, port: port } = proxy
    [ ibrowse: [ proxy_host: ip, proxy_port: port ], timeout: @timeout ]
  end
end