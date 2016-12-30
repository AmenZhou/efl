defmodule Efl.Repo.Migrations.AddUniqueIndexToDadi do
  use Ecto.Migration

  def up do
    create unique_index(:dadi, [:phone])
  end

  def down do
    execute("ALTER TABLE dadi DROP INDEX dadi_phone_index;")
  end
end
