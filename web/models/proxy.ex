defmodule Efl.Proxy do
  require IEx
  require Logger
  @api_key Application.get_env(:proxy_rotator, :api_key)
  @api_rotator_url "http://falcon.proxyrotator.com:51337/?apiKey=#{@api_key}&country=US"

  alias Efl.CacheProxy
  alias Efl.Proxy.DB

  def fetch_proxy do
    fetch_from_db()
  end

  def fetch_from_db do
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
