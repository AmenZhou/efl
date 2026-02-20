defmodule Efl.Proxy do
  require IEx
  require Logger
  @api_key Application.get_env(:proxy_rotator, :api_key)
  @api_rotator_url "http://falcon.proxyrotator.com:51337/?apiKey=#{@api_key}&country=US"

  alias Efl.CacheProxy
  alias Efl.Proxy.DB

  @fetch_from_db_max_retries 3
  @fetch_from_db_retry_sleep_ms 1_500

  alias HttpClient

  @default_connectivity_check_url "http://httpbin.org/ip"
  @connectivity_check_timeout_ms 15_000

  def fetch_proxy do
    case get_proxy_from_cache() do
      {:ok, %{proxy: proxy, record: record}} ->
        Logger.info("Fetch proxy from cache")
        %{proxy: proxy, record: record}
      _ ->
        fetch_from_db(@fetch_from_db_max_retries)
    end
  end

  defp get_proxy_from_cache do
    if Process.whereis(Efl.Proxy.Cache) do
      try do
        Efl.Proxy.Cache.get_proxy()
      catch
        :exit, _ -> :cache_unavailable
      end
    else
      :cache_not_started
    end
  end

  # Builds the proxy map expected by HttpClient from a CacheProxy record.
  def proxy_map_from_record(%CacheProxy{ip: ip, port: port}) when not is_nil(ip) and not is_nil(port) do
    {port_int, _} = Integer.parse(to_string(port))
    %{ip: String.to_charlist(to_string(ip)), port: port_int}
  end

  # Fetches a proxy from the proxies table and checks connectivity with an HTTP request.
  # Uses a short timeout (default 15s) so callers don't get stuck. Options:
  #   :url, :proxy_record, :timeout_ms (default 15_000)
  # Returns {:ok, proxy_info, body} or {:error, reason}.
  def check_connectivity(opts \\ []) do
    url = Keyword.get(opts, :url, @default_connectivity_check_url)
    timeout_ms = Keyword.get(opts, :timeout_ms, @connectivity_check_timeout_ms)
    proxy_record = Keyword.get(opts, :proxy_record)

    record =
      if proxy_record do
        proxy_record
      else
        case DB.random_record || DB.last_record do
          nil -> raise("No proxy in proxies table")
          r -> r
        end
      end

    proxy = proxy_map_from_record(record)
    Logger.info("Checking connectivity for proxy #{inspect(record.ip)}:#{record.port} via #{url} (timeout: #{timeout_ms}ms)")

    result =
      Tesla.get(url,
        opts: [
          adapter: [
            proxy: {proxy.ip, proxy.port},
            recv_timeout: timeout_ms
          ]
        ]
      )

    case result do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        Logger.info("Proxy connectivity OK: #{status}")
        {:ok, %{ip: record.ip, port: record.port, id: record.id}, body}

      {:ok, %{status: status, body: body}} ->
        {:error, "HTTP #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def fetch_from_db(attempts_left \\ @fetch_from_db_max_retries)

  def fetch_from_db(0) do
    raise("Fetch proxy NOT successfully from DB (connection/pool error after retries)")
  end

  def fetch_from_db(attempts_left) do
    proxy_record = DB.random_record || DB.last_record
    case proxy_record do
      %CacheProxy{ ip: ip, port: port } ->
        { port, _ } = Integer.parse(port)
        ip = String.to_charlist(ip)
        proxy = %{ ip: ip, port: port }
        Logger.info("Fetch proxy successfully from DB")
        Logger.info("#{inspect(proxy)}")
        %{ proxy: proxy, record: proxy_record }
      _ ->
        raise("Fetch proxy NOT successfully from DB")
    end
  rescue
    ex in [DBConnection.ConnectionError] ->
      Logger.warning("Proxy fetch_from_db connection error (attempt #{@fetch_from_db_max_retries - attempts_left + 1}): #{inspect(ex)}. Retrying in #{@fetch_from_db_retry_sleep_ms}ms.")
      :timer.sleep(@fetch_from_db_retry_sleep_ms)
      fetch_from_db(attempts_left - 1)
  end

  def fetch_from_api do
    case HTTPotion.get(@api_rotator_url) do
      %{ body: body } ->
        create_proxy(body)
        fetch_from_db()
      %{ message: message } ->
        Logger.info("Unable to get a proxy through api call, #{message}")
        fetch_from_db()
    end
  end

  def proxy_response(body) do
    body |> Poison.Parser.parse!()
  end

  def current_proxy_ip(body) do
    case body |> proxy_response do
      %{ "ip" => ip_str } ->
        String.to_charlist(ip_str)
      _ ->
        raise("Can not get proxy ip address")
    end
  end

  def current_proxy_port(body) do
    case body |> proxy_response do
      %{ "port" => port_str } ->
        { port_int, _ } = Integer.parse(port_str)
        port_int
      _ ->
        raise("Can not get proxy port")
    end
  end

  defp create_proxy(body) do
    try do
      proxy = %{ ip: current_proxy_ip(body), port: current_proxy_port(body) }

      DB.insert_proxy(body)

      Logger.info("Fetch proxy successfully from api")
      Logger.info("#{inspect(proxy)}")
    rescue
      e in RuntimeError ->
        Logger.info("Unable to get a proxy through api call, #{e.message}")
    end
  end
end
