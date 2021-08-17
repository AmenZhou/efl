defmodule Efl.Proxy do
  require IEx
  require Logger
  @api_rotator_url "http://falcon.proxyrotator.com:51337/?apiKey=U8CJ7jTmVtfry4dPWYFKXRsbqSnGo93c&country=US"
  @ets_key "proxy1"
  @ets_table :cached_proxy

  alias Efl.CacheProxy
  alias Efl.Repo
  alias Efl.Proxy.DB

  def fetch_proxy(refresh \\ false) do
    case refresh do
      true ->
        fetch_from_api()
      _ ->
        fetch_from_db()
    end
  end

  def fetch_from_db do
    case CacheProxy.last_record do
      %CacheProxy{ ip: ip, port: port } ->
        { port, _ } = Integer.parse(port)
        ip = String.to_charlist(ip)
        proxy = %{ ip: ip, port: port }
        Logger.info("Fetch proxy successfully from DB")
        Logger.info("#{inspect(proxy)}")
        proxy
      _ ->
        fetch_from_api()
    end
  end

  def fetch_from_ets do
    initialize_ets_table()
    case :ets.lookup(@ets_table, @ets_key) do
      [{ @ets_key, proxy }] ->
        Logger.info("Fetch proxy successfully from ets")
        Logger.info("#{inspect(proxy)}")
        proxy
      _ ->
        fetch_from_api()
    end
  end

  def fetch_from_api do
    case HTTPotion.get(@api_rotator_url) do
      %{ body: body } ->
        proxy = %{ ip: current_proxy_ip(body), port: current_proxy_port(body) }

        initialize_ets_table()
        :ets.insert(@ets_table, { @ets_key, proxy })

        DB.insert_proxy(body)

        Logger.info("Fetch proxy successfully from api")
        Logger.info("#{inspect(proxy)}")
        proxy
      %{ message: message } ->
        raise("Unable to get a proxy through api call, #{message}")
    end
  end

  def initialize_ets_table do
    case :ets.whereis(@ets_table) do
      :undefined ->
        Logger.info("Create a new ets table")
        :ets.new(@ets_table, [:set, :protected, :named_table])
      _ ->
        Logger.info("The ets table exists already")
    end
  end

  def proxy_response(body) do
    body |> Poison.Parser.parse!
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
end
