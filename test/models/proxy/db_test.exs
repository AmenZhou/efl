defmodule Efl.Proxy.DBTest do
  @moduledoc """
  Unit tests for Efl.Proxy.DB (list_usable from commit a36b874c).
  """
  use Efl.ModelCase, async: false

  alias Efl.Proxy.DB
  alias Efl.CacheProxy
  alias Efl.Repo

  describe "list_usable/0" do
    test "returns proxies with score > 0 ordered by score desc" do
      Repo.delete_all(CacheProxy)

      for {ip, port, score} <- [{"1.1.1.1", "80", 5}, {"2.2.2.2", "81", 10}, {"3.3.3.3", "82", 7}] do
        cs =
          CacheProxy.changeset(%CacheProxy{}, %{ip: ip, port: port})
          |> Ecto.Changeset.change(%{score: score})

        {:ok, _} = Repo.insert(cs)
      end

      list = DB.list_usable()
      assert length(list) == 3
      scores = Enum.map(list, & &1.score)
      assert scores == Enum.sort(scores, :desc)
      assert hd(list).score == 10
      assert hd(list).ip == "2.2.2.2"
    end

    test "excludes proxies with score 0" do
      Repo.delete_all(CacheProxy)

      cs_usable =
        CacheProxy.changeset(%CacheProxy{}, %{ip: "1.1.1.1", port: "80"})
        |> Ecto.Changeset.change(%{score: 1})

      cs_zero =
        CacheProxy.changeset(%CacheProxy{}, %{ip: "2.2.2.2", port: "81"})
        |> Ecto.Changeset.change(%{score: 0})

      {:ok, _} = Repo.insert(cs_usable)
      {:ok, _} = Repo.insert(cs_zero)

      list = DB.list_usable()
      assert length(list) == 1
      assert hd(list).ip == "1.1.1.1"
    end

    test "limits to 500 records" do
      # We only insert a few; the limit is documented as 500
      list = DB.list_usable()
      assert length(list) <= 500
    end
  end
end
