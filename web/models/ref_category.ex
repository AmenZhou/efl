defmodule Efl.RefCategory do
  require IEx

  alias Efl.Dadi
  use Efl.Web, :model

  schema "ref_categories" do
    field :name
    field :url
    field :page_size, :integer
    has_many :dadis, Dadi
    timestamps()
  end

  alias Efl.RefCategory
  alias Efl.Repo
  alias Efl.Dadi

  @base_url "http://c.dadi360.com/c/forums/show/"
  @number_of_single_page_rows 60
  @ref_data [
    %{
      name: "FLUSHING_HOUSE_RENT",
      url: "/26.page",
      page_size: 2
    },
    %{
      name: "QUEENS_HOUSE_RENT",
      url: "/53.page",
      page_size: 1
    },
    %{
      name: "ELMHURST_HOUSE_RENT",
      url: "/48.page",
      page_size: 1
    },
    %{
      name: "BLOOKLYN_HOUSE_RENT",
      url: "/46.page",
      page_size: 1
    },
    %{
      name: "MANHATTAN_HOUSE_RENT",
      url: "/47.page",
      page_size: 1
    },
    %{
      name: "OTHER_HOUSE_RENT",
      url: "/89.page",
      page_size: 1
    },
    %{
      name: "NAIL_HIRING",
      url: "/56.page",
      page_size: 1
    },
    %{
      name: "RESTAURANT_HIRING",
      url: "/57.page",
      page_size: 1
    },
    %{
      name: "MASSAGE_HIRING",
      url: "/52.page",
      page_size: 1
    },
    %{
      name: "GENERAL_HIRING",
      url: "/90.page",
      page_size: 1
    },
    %{
      name: "BUSINESS_TRANS",
      url: "/27.page",
      page_size: 1
    },
    %{
      name: "HOUSE_SALE",
      url: "/36.page",
      page_size: 1
    },
    %{
      name: "CARS_SALE",
      url: "/82.page",
      page_size: 1
    },
    %{
      name: "STORE_RENT",
      url: "/27.page",
      page_size: 1
    },
    %{
      name: "USED_GOODS",
      url: "/23.page",
      page_size: 1
    }
  ]

  def seeds do
    for rc <- @ref_data do
      set = changeset(%RefCategory{}, rc)
      Repo.insert(set)
    end
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
