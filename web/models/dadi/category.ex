defmodule Efl.Dadi.Category do
  require IEx

  alias Efl.Repo
  alias Efl.Dadi
  alias Efl.HtmlParsers.Dadi.Category, as: CategoryParser

  #[{ :ok, %Dadi{}}, { :ok, %Dadi{} }, ...]
  def create_items(ref_category) do
    ref_category
    |> CategoryParser.parse
    |> Enum.each(&insert(ref_category, &1))
  end

  def insert(ref_category, dadi \\ %CategoryParser{}) do
    dadi_params = %{ dadi | ref_category_id: ref_category.id }
                  |> Map.from_struct
    set = Dadi.changeset(%Dadi{}, dadi_params)
    case Repo.insert(set) do
      {:ok, struct} -> IO.puts("Insert one record successfully #{Map.get(struct, :title)}")
      {:error, changeset} -> IO.inspect(Map.get(changeset, :errors))
    end
  end
end
