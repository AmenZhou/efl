defmodule Efl.Dadi.Category do
  require IEx

  alias Efl.Repo
  alias Efl.Dadi.Main, as: Dadi
  alias Efl.HtmlParsers.Dadi.Category, as: HtmlParser 

  #[{ :ok, %Dadi{}}, { :ok, %Dadi{} }, ...]
  def create_items(ref_category) do
    ref_category
    |> HtmlParser.parse
    |> Enum.each(&insert(&1, ref_category))
  end

  def insert(dadi, ref_category) do
    dadi_params = dadi
                  |> Map.merge(%{ ref_category_id: ref_category.id })
    set = Dadi.changeset(%Dadi{}, dadi_params)
    case Repo.insert(set) do
      {:ok, struct} -> IO.puts("Insert one record successfully #{Map.get(struct, :title)}")
      {:error, changeset} -> IO.inspect(Map.get(changeset, :errors))
    end
  end
end
