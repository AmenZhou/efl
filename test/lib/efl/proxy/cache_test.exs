defmodule Efl.Proxy.CacheTest do
  @moduledoc """
  Unit tests for Efl.Proxy.Cache (in-memory proxy cache from commit a36b874c).
  """
  use Efl.ModelCase, async: false

  alias Efl.Proxy.Cache
  alias Efl.Proxy.DB
  alias Efl.CacheProxy
  alias Efl.Repo

  describe "get_proxy/0" do
    test "returns {:ok, entry} when cache has proxies after refill_sync" do
      # Ensure we have at least one proxy with score > 0
      cs =
        CacheProxy.changeset(%CacheProxy{}, %{ip: "192.168.1.1", port: "3128"})
        |> Ecto.Changeset.change(%{score: 10})

      {:ok, _} = Repo.insert(cs)
      Cache.refill_sync()

      result = Cache.get_proxy()
      assert {:ok, %{proxy: proxy, record: %CacheProxy{}}} = result
      assert (is_list(proxy.ip) and proxy.port in 1..65535)
      assert proxy.port in 1..65535
    end

    test "returns {:error, :no_proxies} when DB has no usable proxies" do
      # Empty the proxies table for this test (sandbox is isolated per test)
      Repo.delete_all(CacheProxy)
      Cache.refill_sync()

      result = Cache.get_proxy()
      assert result == {:error, :no_proxies}
    end
  end

  describe "refill_sync/0" do
    test "reloads cache from DB" do
      Repo.delete_all(CacheProxy)
      Cache.refill_sync()
      assert {:error, :no_proxies} = Cache.get_proxy()

      cs =
        CacheProxy.changeset(%CacheProxy{}, %{ip: "10.0.0.1", port: "8888"})
        |> Ecto.Changeset.change(%{score: 5})

      {:ok, _} = Repo.insert(cs)
      assert :ok = Cache.refill_sync()
      assert {:ok, %{record: %CacheProxy{ip: "10.0.0.1"}}} = Cache.get_proxy()
    end
  end

  describe "refill/0" do
    test "triggers async refill (cast returns :ok)" do
      assert :ok = Cache.refill()
      # Refill is async; allow a moment for it to complete then verify cache still works
      Process.sleep(100)
      # If we had proxies, get_proxy would return one; we just ensure refill doesn't crash
      _ = Cache.get_proxy()
    end
  end
end
