defmodule ClassificationUtility.Dadi do
  use ClassificationUtility.Web, :model

  #alias ClassificationUtility.Dadi
  alias ClassificationUtility.DadiCategory
  #alias ClassificationUtility.DadiPost
  #alias ClassificationUtility.Repo

  schema "dadi" do
    field :title
    field :url
    field :content
    field :post_date, Ecto.DateTime
    timestamps()
  end

  @base_url "http://c.dadi360.com"

  def start do
    DadiCategory.parse_items(url)
  end

  def url do
    @base_url <> "/c/forums/show/53.page"
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :url, :content, :post_date])
    |> validate_required([:title, :url, :post_date])
  end
end
