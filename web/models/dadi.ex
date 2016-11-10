defmodule ClassificationUtility.Dadi do
  use ClassificationUtility.Web, :model

  schema "dadi" do
    field :title
    field :url
    field :content
    field :post_date, Ecto.DateTime
    timestamps()
  end
  alias ClassificationUtility.Dadi
  alias ClassificationUtility.DadiCategory
  alias ClassificationUtility.Repo

  @base_url "http://c.dadi360.com"

  def post_list do
    DadiCategory.parse_items(url)
    |> Enum.each(&insert/1)
  end

  def insert(item \\ %{}) do
    set = changeset(%Dadi{}, item)
    #IO.inspect set

    case Repo.insert(set) do
      { :ok, _ } ->
        IO.puts("Insert one item")
      { :error, _ } ->
        IO.puts("Error")
    end
  end

  def url do
    @base_url <> "/c/forums/show/53.page"
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :url, :content, :post_date])
    |> validate_required([:title, :url])
  end
end
