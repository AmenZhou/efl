defmodule Efl.Proxy.DB do
  alias Efl.CacheProxy
  alias Efl.Repo
  require Logger

  def insert_proxy(body) do
    proxy = %{ip: body |> ip, port: body |> port}

    result = CacheProxy.changeset(%CacheProxy{}, proxy)
    |> Repo.insert
    Logger.info(inspect(result))
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
end
