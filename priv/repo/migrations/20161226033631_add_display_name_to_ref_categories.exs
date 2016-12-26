defmodule Efl.Repo.Migrations.AddDisplayNameToRefCategories do
  use Ecto.Migration

  def up do
    alter table(:ref_categories) do
      add :display_name, :string
    end
  end

  def down do
    alter table(:ref_categories) do
      remove :display_name
    end
  end
end
