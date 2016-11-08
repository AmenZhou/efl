defmodule ClassificationUtility.Dadi do
  use ClassificationUtility.Web, :model

  schema "dadi" do
    field :title
    field :url
    field :content, :string
    field :post_date, Ecto.DateTime
    timestamps()
  end
  alias ClassificationUtility.Dadi

  @base_url "http://c.dadi360.com"

  def post_list do
    ClassificationUtility.DadiCategory.parse_items(url)
  end

  def url do
    @base_url <> "/c/forums/show/53.page"
  end
end
