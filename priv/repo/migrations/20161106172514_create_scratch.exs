defmodule Efl.Repo.Migrations.CreateScratch do
  use Ecto.Migration

  def change do
    create table(:dadi) do
      add :title, :string
      add :url, :string
      add :post_date, :datetime
      add :content, :text
      #add :category, :integer
      timestamps
    end
  end
end
