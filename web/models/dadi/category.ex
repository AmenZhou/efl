defmodule Efl.Dadi.Category do
  require IEx

  alias Efl.Repo
  alias Efl.Dadi
  alias Efl.Mailer
  alias Efl.HtmlParsers.Dadi.Category, as: CategoryParser

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
        {:ok, struct} -> Logger.info("Insert one record successfully #{Map.get(struct, :title)}")
        {:error, changeset} -> IO.inspect(Map.get(changeset, :errors))
      end
    rescue
      e ->
        Logger.error("Error Efl.Dadi.Category: #{inspect(e)}")
        Mailer.send_alert("Error Efl.Dadi.Category: #{inspect(e)}")
    end
  end

  defp insert(_, _), do: nil
end
