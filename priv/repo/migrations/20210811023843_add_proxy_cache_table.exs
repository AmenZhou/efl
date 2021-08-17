defmodule Efl.Repo.Migrations.AddProxyCacheTable do
  use Ecto.Migration

  def up do
    create table(:proxies) do
      add :ip, :string
      add :port, :string
      timestamps
    end
  end

  def down do
    drop table(:proxies)
  end
end
