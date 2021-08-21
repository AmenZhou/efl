defmodule Efl.Proxy.DB do
  alias Efl.CacheProxy
  alias Efl.Repo
  require Logger
  import Ecto.Query
  require IEx

  def insert_proxy(body) do
    proxy = %{ip: body |> ip, port: body |> port, score: 10}

    { :ok, result } = CacheProxy.changeset(%CacheProxy{}, proxy)
    |> Repo.insert

    Logger.info(inspect(result))
    result
  end

  defp ip(body) do
    case body |> proxy_response do
      %{ "ip" => ip } ->
        ip
      _ ->
        raise("Can not get proxy ip address")
    end
  end

  defp port(body) do
    case body |> proxy_response do
      %{ "port" => port } ->
        port
      _ ->
        raise("Can not get proxy ip address")
    end
  end

  defp proxy_response(body) do
    body |> Poison.Parser.parse!
  end

  def last_record do
    CacheProxy |> last |> Repo.one
  end

  def random_record do
    query =
      from p in CacheProxy,
      where: p.score > 0,
      order_by: fragment("RAND()"),
      limit: 1

    Repo.one(query)
  end

  def increase_score(struct) do
    %CacheProxy{ score: score } = struct

    struct
    |> Ecto.Changeset.change(%{ score: score + 1 })
    |> Repo.update!
  end

  def decrease_score(struct) do
    %CacheProxy{ score: score } = struct
    if score > 0 do
      struct
      |> Ecto.Changeset.change(%{ score: score - 1 })
      |> Repo.update!
    end
  end
end
