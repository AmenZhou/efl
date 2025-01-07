defmodule Efl.RefCategory do
  require IEx

  alias Efl.Dadi
  use Efl.Web, :model

  schema "ref_categories" do
    field :name
    field :display_name
    field :url
    field :page_size, :integer
    has_many :dadis, Dadi
    timestamps()
  end

  alias Efl.RefCategory
  alias Efl.Repo

  @base_url "http://c.dadi360.com/c/forums/show/"
  @number_of_single_page_rows 80
  @ref_data [
    %{
      name: "FLUSHING_HOUSE_RENT",
      display_name: "法拉盛租房",
      url: "/26.page",
      page_size: 4
    },
    %{
      name: "QUEENS_HOUSE_RENT",
      display_name: "皇后区租房",
      url: "/53.page",
      page_size: 2
    },
    %{
      name: "ELMHURST_HOUSE_RENT",
      display_name: "艾姆赫斯特租房",
      url: "/48.page",
      page_size: 2
    },
    %{
      name: "BLOOKLYN_HOUSE_RENT",
      display_name: "布鲁克林租房",
      url: "/46.page",
      page_size: 2
    },
    %{
      name: "MANHATTAN_HOUSE_RENT",
      display_name: "曼哈顿租房",
      url: "/47.page",
      page_size: 2
    },
    %{
      name: "OTHER_HOUSE_RENT",
      display_name: "其他租房",
      url: "/89.page",
      page_size: 2
    },
    %{
      name: "NAIL_HIRING",
      display_name: "美甲招人",
      url: "/56.page",
      page_size: 2
    },
    %{
      name: "RESTAURANT_HIRING",
      display_name: "餐馆招人",
      url: "/57.page",
      page_size: 2
    },
    %{
      name: "GENERAL_HIRING",
      display_name: "招聘",
      url: "/90.page",
      page_size: 2
    },
    %{
      name: "BUSINESS_TRANS",
      display_name: "生意转让",
      url: "/27.page",
      page_size: 2
    },
    %{
      name: "HOUSE_SALE",
      display_name: "房屋出售",
      url: "/36.page",
      page_size: 2
    },
    %{
      name: "CARS_SALE",
      display_name: "汽车出售",
      url: "/82.page",
      page_size: 2
    },
    %{
      name: "USED_GOODS",
      display_name: "二手物品",
      url: "/23.page",
      page_size: 2
    },
    %{
      name: "RENOVATION_SERVICE",
      display_name: "装修服务",
      url: "/44.page",
      page_size: 1
    },
    %{
      name: "AC_HEATER_PLUMBER",
      display_name: "冷暖水电",
      url: "/51.page",
      page_size: 1
    },
    %{
      name: "LAWYER",
      display_name: "律师",
      url: "/74.page",
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
    |> cast(params, [:name, :url, :page_size, :display_name])
  end

  def get_urls(ref_category) do
    page_size = Map.get(ref_category, :page_size, 1)

    for n <- 0..(page_size - 1),
      do: "#{@base_url}#{n * @number_of_single_page_rows}#{ref_category.url}"
  end
end
