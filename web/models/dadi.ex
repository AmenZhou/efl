defmodule Efl.Dadi do
  use Efl.Web, :model

  alias Efl.RefCategory
  alias Efl.Dadi.Category
  alias Efl.Dadi.Post
  alias Efl.Repo
  alias Efl.Dadi
  alias Efl.TimeUtil
  alias Efl.Mailer
  alias Efl.EtsManager
  require IEx
  require Logger

  schema "dadi" do
    field :title
    field :url
    field :content
    field :phone
    field :post_date, :date
    belongs_to :ref_category, RefCategory, foreign_key: :ref_category_id
    timestamps()
  end

  def start do
    try do
      Task.start_link(fn -> main() end)
    rescue
      e in RuntimeError ->
        Logger.error("Error Efl.Dadi.start: #{e.message}")
        Mailer.send_alert("Error Efl.Dadi.start: #{e.message}")
        :ets.insert(@ets_table, { @ets_key, false })
    end
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> changeset_cast(params)
    |> validate_required([:title, :url, :post_date, :ref_category_id])
    |> unique_constraint(:url)
    |> validate_post_date
  end

  def update_changeset(struct, params \\ %{}) do
    struct
    |> update_cast(params)
    |> validate_required([:content])
  end

  defp changeset_cast(struct, %{phone: phone} = params) when is_binary(phone) do
    cast(struct, params, [:title, :url, :content, :post_date, :ref_category_id, :phone])
  end

  defp changeset_cast(struct, params) do
    cast(struct, params, [:title, :url, :content, :post_date, :ref_category_id])
  end

  defp update_cast(struct, %{phone: phone} = params) when is_binary(phone) do
    cast(struct, params, [:content, :phone])
  end

  defp update_cast(struct, params) do
    cast(struct, params, [:content])
  end

  defp validate_post_date(changeset) do
    post_date = get_field(changeset, :post_date) |> Timex.to_date
    validate_post_date(changeset, TimeUtil.target_date, post_date)
  end

  defp validate_post_date(changeset, ideal_date, post_date) do
    if Timex.compare(ideal_date, post_date) != 0 do
      add_error(changeset, :post_date, "The post date is not ideal")
    else
      changeset
    end
  end

  defp main do
    Logger.info("Deleting all records")
    Repo.delete_all(Dadi)
    Repo.delete_all(RefCategory)

    Logger.info("RefCategory seeds")
    RefCategory.seeds

    Logger.info("Start fetching categories")
    RefCategory
    |> Repo.all
    |> Enum.each(fn(cat) ->
      Category.create_items(cat)
    end)

    Logger.info("Start fetching posts")
    Post.update_contents 

    Logger.info("Exporting Xls file")
    Efl.Xls.Dadi.create_xls

    Logger.info("Sending Emails")
    Mailer.send_email_with_xls 
  end
end
