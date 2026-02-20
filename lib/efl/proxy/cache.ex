defmodule Efl.Proxy.Cache do
  @moduledoc """
  In-memory cache of proxies loaded from the DB at startup and on refill.
  Callers get a proxy via get_proxy/0 instead of querying the DB per request.
  """
  use GenServer
  require Logger

  alias Efl.Proxy
  alias Efl.Proxy.DB

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns one proxy from the cache at random.
  Returns %{proxy: proxy_map, record: %CacheProxy{}}.
  Refills from DB if cache is empty; raises if still empty after refill.
  """
  def get_proxy do
    GenServer.call(__MODULE__, :get_proxy, :infinity)
  end

  @doc """
  Reloads the proxy list from the DB and replaces the cache state.
  """
  def refill do
    GenServer.cast(__MODULE__, :refill)
  end

  # Call refill and wait for it to complete (for get_proxy to use after empty).
  def refill_sync do
    GenServer.call(__MODULE__, :refill_sync, :infinity)
  end

  @impl true
  def init(_opts) do
    state = load_from_db()
    if length(state) == 0 do
      Logger.warning("Efl.Proxy.Cache started with no proxies in DB")
    else
      Logger.info("Efl.Proxy.Cache loaded #{length(state)} proxies")
    end
    {:ok, state}
  end

  @impl true
  def handle_call(:get_proxy, _from, []) do
    state = load_from_db()
    if length(state) == 0 do
      {:reply, {:error, :no_proxies}, []}
    else
      entry = Enum.random(state)
      {:reply, {:ok, entry}, state}
    end
  end

  def handle_call(:get_proxy, _from, state) when is_list(state) and length(state) > 0 do
    entry = Enum.random(state)
    {:reply, {:ok, entry}, state}
  end

  def handle_call(:refill_sync, _from, _state) do
    state = load_from_db()
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast(:refill, _state) do
    state = load_from_db()
    Logger.info("Efl.Proxy.Cache refilled with #{length(state)} proxies")
    {:noreply, state}
  end

  defp load_from_db do
    DB.list_usable()
    |> Enum.map(fn record ->
      proxy = Proxy.proxy_map_from_record(record)
      %{proxy: proxy, record: record}
    end)
  end
end
