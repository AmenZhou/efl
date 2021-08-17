defmodule Efl.CacheProxy do
  use Efl.Web, :model
  import Ecto.Query

  alias Efl.CacheProxy
  alias Efl.Repo

  schema "proxies" do
    field :ip
    field :port
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:ip, :port])
  end

  def last_record do
    CacheProxy |> last |> Repo.one
  end
end

