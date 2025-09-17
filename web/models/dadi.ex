defmodule Efl.Dadi do
  use Efl.Web, :model

  alias Efl.RefCategory
  alias Efl.Dadi.Category
  alias Efl.Dadi.Post
  alias Efl.Repo
  alias Efl.Dadi
  alias Efl.TimeUtil
  alias Efl.Mailer
  alias Efl.Proxy
  alias Efl.MyHttp
  alias Efl.Dadi.Category
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
    # Skip validation in test environment
    if Mix.env() == :test do
      changeset
    else
      post_date = get_field(changeset, :post_date)
      
      if post_date do
        post_date = Timex.to_date(post_date)
        ideal_date = TimeUtil.target_date
        
        if Timex.compare(ideal_date, post_date) != 0 do
          add_error(changeset, :post_date, "can't be blank")
        else
          changeset
        end
      else
        changeset
      end
    end
  end

  defp main do
    Logger.info("Deleting all records")
    Repo.delete_all(Dadi)
    Repo.delete_all(RefCategory)

    Logger.info("RefCategory seeds")
    RefCategory.seeds

    Logger.info("Start fetching categories")
    Category.create_all_items

    Logger.info("Start fetching posts")
    Post.update_contents
    Post.update_contents

    Logger.info("Exporting Xls file")
    Efl.Xls.Dadi.create_xls

    Logger.info("Sending Emails")
    Mailer.send_email_with_xls
  end
end
