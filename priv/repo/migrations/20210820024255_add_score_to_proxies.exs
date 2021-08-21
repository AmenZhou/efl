defmodule Efl.Repo.Migrations.AddScoreToProxies do
  use Ecto.Migration

  def up do
    alter table(:proxies) do
      add :score, :integer, default: 10
    end
  end

  def down do
    alter table(:proxies) do
      remove :score
    end
  end
end
