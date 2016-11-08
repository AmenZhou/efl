defmodule ClassificationUtility.Dadi do
  use Ecto.Schema
  @base_url "http://c.dadi360.com"

  def post_list do
    ClassificationUtility.DadiCategory.parse_items(url)
  end

  def url do
    @base_url <> "/c/forums/show/53.page"
  end
end
