defmodule ClassificationUtility.RefCategory do
  use ClassificationUtility.Web, :model

  schema "ref_categories" do
    field :name
    field :url
    #has_many :dadi_posts, Dadi
    timestamps()
  end

  alias ClassificationUtility.RefCategory
  alias ClassificationUtility.Repo

  def seeds do
    set = changeset(%RefCategory{}, %{ name: "FLUSHING_HOUSE_RENTAL", url: "/c/forums/show/53.page" })
    Repo.insert(set)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :url])
  end
end
