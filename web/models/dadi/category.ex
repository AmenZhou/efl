defmodule Efl.Dadi.Category do
  require IEx
  require Logger

  alias Efl.Repo
  alias Efl.Dadi
  alias Efl.Mailer
  alias Efl.Dadi.Category
  alias Efl.RefCategory
  alias Efl.HtmlParsers.Dadi.Category, as: CategoryParser
  @task_interval 2_000
  @task_timeout 12_000_000

  def create_all_items do
    ref_categories = RefCategory |> Repo.all
    Logger.info("Found #{length(ref_categories)} ref_categories: #{inspect(Enum.map(ref_categories, & &1.id))}")
    
    ref_categories
    |> Enum.map(fn(cat) ->
      :timer.sleep(@task_interval)
      Task.async(Category , :create_items, [cat])
    end)
    |> Enum.map(fn(task) ->
      Task.await(task, @task_timeout)
    end)
  end

  #[{ :ok, %Dadi{}}, { :ok, %Dadi{} }, ...]
  def create_items(ref_category) do
    ref_category
    |> CategoryParser.parse
    |> Enum.each(&insert(ref_category, &1))
  end

  defp insert(ref_category, dadi) when is_map(dadi) do
    try do
      Logger.info("Processing ref_category: id=#{ref_category.id}, name=#{ref_category.name}")
      dadi_params = %{ dadi | ref_category_id: ref_category.id }
                    |> Map.from_struct
      
      # Log the data being inserted for debugging
      target_date = Efl.TimeUtil.target_date()
      Logger.info("Target date for validation: #{target_date}")
      Logger.info("Original dadi struct: title=#{dadi.title}, post_date=#{inspect(dadi.post_date)}, url=#{dadi.url}")
      Logger.info("Converted dadi_params: title=#{dadi_params[:title]}, post_date=#{inspect(dadi_params[:post_date])}, url=#{dadi_params[:url]}, ref_category_id=#{dadi_params[:ref_category_id]}")
      Logger.info("Attempting to insert dadi record: title=#{dadi.title}, post_date=#{dadi.post_date}, url=#{dadi.url}, ref_category_id=#{ref_category.id}")
      
      set = Dadi.changeset(%Dadi{}, dadi_params)
      case Repo.insert(set) do
        {:ok, struct} ->
          Logger.info("Successfully inserted dadi record with ID: #{struct.id}")
        {:error, changeset} ->
          error_details = changeset.errors
          |> Enum.map(fn {field, {message, _}} -> "#{field}: #{message}" end)
          |> Enum.join(", ")
          Logger.error("Failed to insert dadi record: #{error_details}")
          Logger.error("Data was: title=#{dadi.title}, post_date=#{dadi.post_date}, url=#{dadi.url}")
      end
    rescue
      e ->
        Logger.error("Error Efl.Dadi.Category: #{inspect(e)}")
        Mailer.send_alert("Error Efl.Dadi.Category: #{inspect(e)}")
    end
  end

  defp insert(_, _), do: nil
end
