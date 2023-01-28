defmodule Efl.MyHttp do
  require IEx
  require Logger

  alias Efl.Proxy
  alias Efl.Proxy.DB
  @timeout 120_000
  @max_attempt 50
  @max_proxy_from_api 20
  @request_interval 1_000
  @intermission_time 10_000
  @intermission 10

  def request(url, attempts \\ 1)

  def request(url, attempts) when rem(attempts, @intermission) == 0 do
    :timer.sleep(@intermission_time)
    request(url, attempts + 1)
  end

  def request(url, attempts) when attempts < @max_attempt and rem(attempts, @intermission) != 0 do
    :timer.sleep(@request_interval)
    %{ proxy: proxy, record: record } = Proxy.fetch_proxy()

    case HttpClient.get(url, opts: [adapter: [proxy: proxy_config(proxy), timeout: @timeout]]) do
      { :ok, %{ body: body, status: status } } ->
        Logger.info("#{inspect(body)} #{status}")
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
      { :error, message } ->
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
    { ip, port }
  end

  def number_of_proxies_needed do
    case @max_proxy_from_api <= DB.number_of_proxies do
      true -> []
      false -> (1..(@max_proxy_from_api - DB.number_of_proxies))
    end
  end
end
