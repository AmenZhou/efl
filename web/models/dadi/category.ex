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
    RefCategory
    |> Repo.all
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
      dadi_params = %{ dadi | ref_category_id: ref_category.id }
                    |> Map.from_struct
      set = Dadi.changeset(%Dadi{}, dadi_params)
      case Repo.insert(set) do
        {:ok, struct} ->
          message = Map.get(struct, :content) |> inspect
          Logger.info("Insert one record successfully #{message}")
        {:error, changeset} ->
          message = Map.get(changeset, :errors) |> inspect
          Logger.error(message)
      end
    rescue
      e ->
        Logger.error("Error Efl.Dadi.Category: #{inspect(e)}")
        Mailer.send_alert("Error Efl.Dadi.Category: #{inspect(e)}")
    end
  end

  defp insert(_, _), do: nil
end
