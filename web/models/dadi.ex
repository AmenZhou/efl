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
    # Check if process is already running
    case Process.whereis(:dadi_processor) do
      nil ->
        # No process running, start a new one
        Logger.info("Starting DADI processing...")
        {:ok, pid} = Task.start_link(fn -> 
          # Register this process with error handling
          try do
            Process.register(self(), :dadi_processor)
            main()
          rescue
            ArgumentError ->
              # Registration failed, process already exists
              Logger.warning("DADI process registration failed - another process already running")
              exit(:already_running)
          end
        end)
        {:ok, pid}
      pid when is_pid(pid) ->
        # Process already running
        Logger.warning("DADI processing already in progress (PID: #{inspect(pid)})")
        {:error, :already_running}
    end
  rescue
    e in RuntimeError ->
      Logger.error("Error Efl.Dadi.start: #{e.message}")
      Mailer.send_alert("Error Efl.Dadi.start: #{e.message}")
      {:error, e}
  end

  def stop do
    case Process.whereis(:dadi_processor) do
      nil ->
        Logger.info("No DADI processing running to stop")
        {:ok, :not_running}
      pid when is_pid(pid) ->
        Logger.info("Stopping DADI processing (PID: #{inspect(pid)})")
        Process.exit(pid, :kill)
        Process.unregister(:dadi_processor)
        {:ok, :stopped}
    end
  end

  def status do
    case Process.whereis(:dadi_processor) do
      nil -> {:not_running, nil}
      pid when is_pid(pid) -> {:running, pid}
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
    # Skip validation in test environment and for development
    if Mix.env() == :test or Mix.env() == :dev do
      changeset
    else
      post_date = get_field(changeset, :post_date)
      
      if post_date do
        post_date = Timex.to_date(post_date)
        ideal_date = TimeUtil.target_date
        
        # Allow posts from the last 30 days to be more flexible
        days_diff = Timex.diff(ideal_date, post_date, :days)
        
        if days_diff < 0 or days_diff > 30 do
          # Log the rejection for debugging but don't send alerts for old posts
          Logger.info("Rejecting post from #{post_date} (target: #{ideal_date}, diff: #{days_diff} days)")
          add_error(changeset, :post_date, "can't be blank")
        else
          changeset
        end
      else
        changeset
      end
    end
  end

  def main do
    try do
      Logger.info("=== DADI Processing Started ===")
      
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
      case Mailer.send_email_with_xls do
        {:ok, _} -> 
          Logger.info("Email sent successfully")
        {:error, reason} -> 
          Logger.error("Email sending failed: #{inspect(reason)}")
        other ->
          Logger.info("Email sending result: #{inspect(other)}")
      end

      Logger.info("=== DADI Processing Completed Successfully ===")
    rescue
      e ->
        Logger.error("Error in DADI processing: #{inspect(e)}")
        Mailer.send_alert("Error in DADI processing: #{inspect(e)}")
    after
      # Always clean up the process registration
      Process.unregister(:dadi_processor)
      Logger.info("DADI processing process cleaned up and exiting")
    end
  end

end
