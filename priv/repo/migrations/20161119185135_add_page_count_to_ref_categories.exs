defmodule Efl.Repo.Migrations.AddPageCountToRefCategories do
  use Ecto.Migration

  def up do
    alter table(:ref_categories) do
      add :page_size, :integer
    end
  end

  def down do
    alter table(:ref_categories) do
      remove :page_size
    end
  end
end
