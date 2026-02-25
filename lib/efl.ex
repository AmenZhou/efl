defmodule Efl do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # When EFL_SCRIPT_MODE=1 (e.g. production smoke test), skip starting the endpoint to avoid port conflict
    start_endpoint? = System.get_env("EFL_SCRIPT_MODE") != "1"

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Efl.Repo, []),
      # In-memory proxy cache (loads from DB at startup)
      worker(Efl.Proxy.Cache, []),
      # Start the endpoint when the application starts (omit in script mode)
      (start_endpoint? && supervisor(Efl.Endpoint, [])) || nil,
      # Start your own worker by calling: Efl.Worker.start_link(arg1, arg2, arg3)
      # worker(Efl.Worker, [arg1, arg2, arg3]),
    ] |> Enum.reject(&is_nil/1)

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Efl.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Efl.Endpoint.config_change(changed, removed)
    :ok
  end
end