defmodule Efl.Dadi.Post do
  require IEx
  require Logger

  alias Efl.Repo
  alias Efl.Dadi
  alias Efl.HtmlParsers.Dadi.Post, as: PostParser
  import Ecto.Query, only: [from: 2]

  @max_posts 2_000
  @task_interval 2_000
  @task_timeout 12_000_000
  @max_concurreny 5

  def update_contents do
    get_all_blank_records()
      |> Enum.map(fn(d) -> d.url end)
      |> async_process_posts
  end

  defp async_process_posts(urls) do
    urls
    |> Task.async_stream(fn url ->
      :timer.sleep(@task_interval)
      Efl.Dadi.Post.parse_and_update_post(url)
    end,
    max_concurrency: @max_concurreny,
    timeout: @task_timeout)
    |> Enum.to_list
  end

  def parse_and_update_post(url) do
    url
     |> PostParser.parse_post
     |> update_by_parsed_result
  end

  defp get_all_blank_records do
    query = from d in Dadi,
      where: is_nil(d.content),
      #This limit is used to prevent generating huge amount of http calls
      limit: @max_posts
    Repo.all(query)
  end

  defp find_dadi_by_url(url) when is_nil(url), do: nil

  defp find_dadi_by_url(url) do
    query = from d in Dadi,
      where: (d.url == ^url),
      limit: 1
    Repo.one(query)
  end

  defp update(dadi, _) when is_nil(dadi), do: nil

  defp update(dadi, params) do
    params = Map.from_struct(params)
    set = Dadi.update_changeset(dadi, params)
    case Repo.update(set) do
      {:ok, struct} ->
        message = Map.get(struct, :content) |> inspect
        Logger.info("Insert one record successfully #{message}")
      {:error, changeset} ->
        message = Map.get(changeset, :errors) |> inspect
        Logger.error(message)
    end
  end

  #when the argument is a %PostParser{}
  defp update_by_parsed_result(p) when is_map(p) do
    p.url
    |> find_dadi_by_url
    |> update(p)
  end

  defp update_by_parsed_result(_), do: nil
end
