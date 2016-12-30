defmodule Efl.Dadi do
  use Efl.Web, :model
  use Timex.Ecto.Timestamps

  alias Efl.RefCategory
  alias Efl.Dadi.Category
  alias Efl.Dadi.Post
  alias Efl.Repo
  alias Efl.TimeUtil
  require IEx

  schema "dadi" do
    field :title
    field :url
    field :content
    field :phone
    field :post_date, Timex.Ecto.DateTime
    belongs_to :ref_category, RefCategory, foreign_key: :ref_category_id
    timestamps()
  end

  def start(ref_category) do
    ref_category
    |> Category.create_items

    Post.update_contents 
  end

  def start do
    RefCategory
    |> Repo.all
    |> Enum.each(fn(cat) ->
      Category.create_items(cat)
    end)
    
    Post.update_contents 
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :url, :content, :post_date, :ref_category_id, :phone])
    |> validate_required([:title, :url, :post_date, :ref_category_id])
    |> unique_constraint(:url, :phone)
    |> validate_post_date
  end

  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:content, :phone])
    |> validate_required([:content])
  end

  defp validate_post_date(changeset) do
    post_date = get_field(changeset, :post_date) |> Timex.to_date
    validate_post_date(changeset, TimeUtil.target_date, post_date)
  end

  defp validate_post_date(changeset, ideal_date, post_date) do
    if Timex.compare(ideal_date, post_date) != 0 do
      IO.inspect(post_date)
      add_error(changeset, :post_date, "The post date is not ideal")
    else
      changeset
    end 
  end
end
