defmodule Efl.MyHttp do
  require IEx
  require Logger
  alias Efl.Proxy
  alias Efl.Proxy.DB
  @timeout 120_000
  @fetch_api 10
  @max_attempt 100
  @max_proxy_from_api 50

  def request(url, attempts \\ 1)
  def request(url, attempts) when attempts < @max_attempt do
    %{ proxy: proxy, record: record } = Proxy.fetch_proxy()

    case HTTPotion.get(url, proxy_config(proxy)) do
      %{ body: body } ->
        if !String.match?(body, ~r/www.dadi360.com\/img\/dadiicon.ico/) do
          Logger.info("Fetch fail, #{url}, NO ACCESS")
          Logger.info("Retry... #{attempts+1} attempts")
          DB.decrease_score(record)
          request(url, attempts + 1)
        else
          Logger.info("Fetch a page successfully, #{url}")
          DB.increase_score(record)
          body
        end
      %{ message: message } ->
        Logger.info("Fetch fail, #{url}, #{message}")
        Logger.info("Retry... #{attempts+1} attempts")
        DB.decrease_score(record)
        request(url, attempts + 1)
    end
  end

  def request(url, attempts) when attempts >= @max_attempt do
    raise("Has reached the max attempts of fetching category page, #{url}")
  end

  def proxy_config(proxy) do
    %{ ip: ip, port: port } = proxy
    [ ibrowse: [ proxy_host: ip, proxy_port: port ], timeout: @timeout ]
  end

  def number_of_proxies_needed do
    case @max_proxy_from_api <= DB.number_of_proxies do
      true -> 0
      false -> @max_proxy_from_api - DB.number_of_proxies
    end
  end
end
