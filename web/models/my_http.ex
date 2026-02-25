defmodule Efl.MyHttp do
  require IEx
  require Logger

  alias Efl.Proxy
  alias Efl.Proxy.DB
  @max_attempt 50
  @max_proxy_from_api 20
  @request_interval 1_000
  @intermission_time 10_000
  @intermission 10

  # All requests go through a proxy (HttpClient.get(url, proxy)); there is no direct (no-proxy) path.
  # If the proxy is unreachable or fails, Tesla.Adapter.Hackney returns {:error, reason} and we retry
  # with another proxy until @max_attempt is reached.
  def request(url, attempts \\ 1)

  def request(url, attempts) when rem(attempts, @intermission) == 0 do
    :timer.sleep(@intermission_time)
    request(url, attempts + 1)
  end

  def request(url, attempts) when attempts < @max_attempt and rem(attempts, @intermission) != 0 do
    :timer.sleep(@request_interval)
    %{ proxy: proxy, record: record } = Proxy.fetch_proxy()

    case HttpClient.get(url, proxy) do
      { :ok, %{ body: body, status: status } } ->
        body_has_icon = String.match?(body || "", ~r/\/img\/dadiicon.ico/)
        Logger.info("#{inspect(body)} #{status}")
        if !body_has_icon do
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

  def number_of_proxies_needed do
    case @max_proxy_from_api <= DB.number_of_proxies do
      true -> []
      false -> (1..(@max_proxy_from_api - DB.number_of_proxies))
    end
  end
end
