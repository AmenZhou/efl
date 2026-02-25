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
    body |> Poison.Parser.parse!()
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

  @list_usable_max 500

  def list_usable do
    query =
      from p in CacheProxy,
      where: p.score > 0,
      order_by: [desc: :score],
      limit: @list_usable_max

    Repo.all(query)
  end

  # Atomic updates by id to avoid Ecto.StaleEntryError when multiple requests
  # (e.g. Category.raw_items) use the same proxy concurrently.
  def increase_score(struct) do
    %CacheProxy{ id: id } = struct
    from(p in CacheProxy, where: p.id == ^id, update: [set: [score: fragment("? + 1", p.score), updated_at: ^NaiveDateTime.utc_now()]])
    |> Repo.update_all([])
    :ok
  end

  def decrease_score(struct) do
    %CacheProxy{ id: id, score: score } = struct
    if score > 0 do
      from(p in CacheProxy, where: p.id == ^id and p.score > 0,
        update: [set: [score: fragment("? - 1", p.score), updated_at: ^NaiveDateTime.utc_now()]])
      |> Repo.update_all([])
    end
    :ok
  end

  def number_of_proxies do
    query = from p in CacheProxy,
      where: p.score > 0,
      select: count(p.id)

    Repo.one(query)
  end
end
