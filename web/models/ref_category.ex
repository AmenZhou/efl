defmodule ClassificationUtility.RefCategory do
  require IEx

  use ClassificationUtility.Web, :model

  schema "ref_categories" do
    field :name
    field :url
    field :page_size, :integer
    #has_many :dadi_posts, Dadi
    timestamps()
  end

  alias ClassificationUtility.RefCategory
  alias ClassificationUtility.Repo

  @base_url "http://c.dadi360.com/c/forums/show/"
  @number_of_single_page_rows 60

  def seeds do
    set = changeset(
                    %RefCategory{},
                    %{
                      name: "FLUSHING_HOUSE_RENTAL",
                      url: "/26.page",
                      page_size: 2
                    }
    )
    Repo.insert(set)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :url, :page_size])
  end

  def get_urls(ref_category) do
    page_size = Map.get(ref_category, :page_size, 1)

    for n <- 0..(page_size - 1),
      do: "#{@base_url}#{n * @number_of_single_page_rows}#{ref_category.url}"
  end
end
