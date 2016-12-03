defmodule ClassificationUtility.Dadi.Category do
  require IEx

  alias ClassificationUtility.Repo
  alias ClassificationUtility.Dadi.Main, as: Dadi
  alias ClassificationUtility.HtmlParsers.Dadi.Category, as: HtmlParser 

  @base_url "http://c.dadi360.com/"

  #def parse_and_return_post_urls(url) do
    #items = parse_items(url)
    #case items do
      #{ :error, message } -> { :error, message }
      #{ :ok, items } ->
        #Enum.map(items, fn(item) ->
          #case item do
            #{ :ok, item } ->
              #item
              #|> Map.get(:url)
            #{ :error, message } ->
              #IO.puts message
          #end
        #end)
    #end
  #end

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
