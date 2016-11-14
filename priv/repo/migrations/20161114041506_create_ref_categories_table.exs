defmodule ClassificationUtility.Repo.Migrations.CreateRefCategoriesTable do
  use Ecto.Migration

  def up do
    create table(:ref_categories) do
      add :name, :string
      add :url, :string
      timestamps
    end

    alter table(:dadi) do
      add :ref_category_id, references(:ref_categories)
    end
  end

  def down do
    execute("ALTER TABLE dadi DROP FOREIGN KEY dadi_ref_category_id_fkey;")
    alter table(:dadi) do
      remove :ref_categories
    end

    drop table(:ref_categories)
  end
end
