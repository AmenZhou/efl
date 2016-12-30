defmodule Efl.Dadi.Post do
  require IEx

  alias Efl.Repo
  alias Efl.Dadi
  alias Efl.HtmlParsers.Dadi.Post, as: HtmlParser
  import Ecto.Query, only: [from: 2] 

  @max_posts 500

  def update_contents do
    get_all_blank_records
    |> Enum.map(fn(d) ->
      d.url
      |> HtmlParser.parse_post
      |> update_by_parsed_result
    end)
  end

  defp get_all_blank_records do
    query = from d in Dadi,
      where: is_nil(d.content),
      #This limit is used to prevent generating huge amount of http calls
      limit: @max_posts
    Repo.all(query)
  end

  defp find_dadi_by_url(url) do
    query = from d in Dadi,
      where: (d.url == ^url),
      limit: 1
    Repo.one(query)
  end

  defp update(dadi, params) do
    set = Dadi.update_changeset(dadi, params)
    case Repo.update(set) do
      {:ok, struct} -> IO.puts("Insert one record successfully #{Map.get(struct, :content)}")
      {:error, changeset} -> IO.inspect(Map.get(changeset, :errors))
    end
  end

  defp update_by_parsed_result(p) when is_map(p) do
    p
    |> Map.get(:url)
    |> find_dadi_by_url
    |> update(p)
  end

  defp update_by_parsed_result(_), do: nil
end
