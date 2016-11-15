defmodule ClassificationUtility.Dadi do
  use ClassificationUtility.Web, :model

  #alias ClassificationUtility.Dadi
  alias ClassificationUtility.RefCategory
  alias ClassificationUtility.DadiCategory
  #alias ClassificationUtility.DadiPost
  alias ClassificationUtility.Repo

  schema "dadi" do
    field :title
    field :url
    field :content
    field :post_date, Ecto.DateTime
    belongs_to :ref_category, RefCategory, foreign_key: :ref_category_id
    timestamps()
  end

  @base_url "http://c.dadi360.com"

  def start(ref_category \\ %{}) do
    ref_category = Repo.get(RefCategory, 1)
    DadiCategory.parse_items(ref_category)
  end

  def url do
    @base_url <> "/c/forums/show/53.page"
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :url, :content, :post_date, :ref_category_id])
    |> validate_required([:title, :url, :post_date, :ref_category_id])
  end

  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:content])
    |> validate_required([:content])
  end
end
