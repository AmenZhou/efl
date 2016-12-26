defmodule Efl.Repo.Migrations.AddPhoneToDadi do
  use Ecto.Migration

  def up do
    alter table(:dadi) do
      add :phone, :string
    end
  end

  def down do
    alter table(:dadi) do
      remove :phone
    end
  end
end
