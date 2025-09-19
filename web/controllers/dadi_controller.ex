defmodule Efl.DadiController do
  use Efl.Web, :controller
  alias Efl.Repo
  alias Efl.Dadi
  require IEx

  def index(conn, _params) do
    posts = Dadi |> Repo.all
    render conn, "index.html", %{posts: posts}
  end

  def scratch(conn, _params) do
    ip_addr = to_string(:inet_parse.ntoa(conn.remote_ip))
    if ip_addr == "127.0.0.1" do
      case Efl.Dadi.start do
        {:ok, pid} ->
          text conn, "DADI processing started successfully (PID: #{inspect(pid)})"
        {:error, :already_running} ->
          text conn, "DADI processing already in progress. Please wait for completion."
        {:error, reason} ->
          text conn, "Failed to start DADI processing: #{inspect(reason)}"
      end
    else
      text conn, "No permission"
    end
  end

  def status(conn, _params) do
    case Dadi.status do
      {:not_running, _} ->
        text conn, "DADI processing: Not running"
      {:running, pid} ->
        text conn, "DADI processing: Running (PID: #{inspect(pid)})"
    end
  end

  def stop(conn, _params) do
    ip_addr = to_string(:inet_parse.ntoa(conn.remote_ip))
    if ip_addr == "127.0.0.1" do
      case Dadi.stop do
        {:ok, :not_running} ->
          text conn, "DADI processing: Not running"
        {:ok, :stopped} ->
          text conn, "DADI processing stopped successfully"
      end
    else
      text conn, "No permission"
    end
  end
end
