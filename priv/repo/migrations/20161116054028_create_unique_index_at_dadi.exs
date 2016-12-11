defmodule Efl.Repo.Migrations.CreateUniqueIndexAtDadi do
  use Ecto.Migration

  def up do
    create unique_index(:dadi, [:url])
  end

  def down do
    execute("ALTER TABLE dadi DROP INDEX dadi_url_index;")
  end
end
