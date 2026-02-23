defmodule Efl.ProxyTest do
  @moduledoc """
  Unit tests for Efl.Proxy (proxy cache integration, proxy_map_from_record, check_connectivity from commit a36b874c).
  """
  use Efl.ModelCase, async: false

  alias Efl.Proxy
  alias Efl.CacheProxy
  alias Efl.Repo

  describe "proxy_map_from_record/1" do
    test "builds map with string ip and string port" do
      record = %CacheProxy{id: 1, ip: "192.168.1.1", port: "8080", score: 10}
      map = Proxy.proxy_map_from_record(record)
      assert map.ip == '192.168.1.1'
      assert map.port == 8080
    end

    test "builds map with integer port" do
      record = %CacheProxy{id: 1, ip: "10.0.0.1", port: 9090, score: 10}
      map = Proxy.proxy_map_from_record(record)
      assert map.port == 9090
      assert map.ip == '10.0.0.1'
    end

    test "converts port string to integer" do
      record = %CacheProxy{id: 1, ip: "1.2.3.4", port: "443", score: 10}
      map = Proxy.proxy_map_from_record(record)
      assert map.port == 443
    end
  end

  describe "check_connectivity/1" do
    test "accepts :proxy_record option and uses it" do
      # Use an invalid/unreachable proxy so we get a fast error (no real HTTP)
      record = %CacheProxy{id: 0, ip: "192.0.2.1", port: "1", score: 10}
      result = Proxy.check_connectivity(proxy_record: record, timeout_ms: 500)
      assert {:error, _reason} = result
    end

    test "accepts :url and :timeout_ms options" do
      record = %CacheProxy{id: 0, ip: "192.0.2.1", port: "1", score: 10}
      result =
        Proxy.check_connectivity(
          proxy_record: record,
          url: "http://example.invalid/",
          timeout_ms: 100
        )

      assert {:error, _reason} = result
    end
  end

  describe "fetch_proxy/0" do
    test "returns proxy from cache when cache has entries" do
      # Rely on cache_test having refilled with a proxy, or insert one and refill
      cs =
        CacheProxy.changeset(%CacheProxy{}, %{ip: "127.0.0.1", port: "9999"})
        |> Ecto.Changeset.change(%{score: 10})

      {:ok, _} = Repo.insert(cs)
      Efl.Proxy.Cache.refill_sync()

      result = Proxy.fetch_proxy()
      assert %{proxy: %{ip: _ip, port: _port}, record: %CacheProxy{}} = result
    end
  end
end
