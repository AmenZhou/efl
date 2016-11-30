defmodule ClassificationUtility.Dadi.Main do
  use ClassificationUtility.Web, :model

  alias ClassificationUtility.RefCategory
  alias ClassificationUtility.Dadi.Category
  alias ClassificationUtility.Repo

  schema "dadi" do
    field :title
    field :url
    field :content
    field :post_date, Ecto.DateTime
    belongs_to :ref_category, RefCategory, foreign_key: :ref_category_id
    timestamps()
  end

  def start(ref_category \\ %{}) do
    ref_category = RefCategory |> first |> Repo.one
    Category.create_items(ref_category)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :url, :content, :post_date, :ref_category_id])
    |> validate_required([:title, :url, :post_date, :ref_category_id])
    |> unique_constraint(:url)
  end
end
