defmodule Efl.Xls.Dadi do
  require Elixlsx

  alias Elixlsx.Sheet
  alias Elixlsx.Workbook
  alias Efl.Repo
  alias Efl.RefCategory
  alias Efl.Dadi
  alias Efl.TimeUtil
  import Ecto.Query
  use Timex

  def create_xls do
    %Workbook{sheets: sheets}
    |> Elixlsx.write_to(file_name)
  end

  def sheets do
    available_dadis 
    |> Enum.map(&one_sheet(&1))
  end

  def one_sheet(ref_category) do
    %Sheet{
      name: ref_category.display_name,
      rows: ref_category.dadis |> rows
    }
    |> Sheet.set_row_height(3, 40)
  end

  def rows(dadis) do
    dadis
    |> Enum.map(&one_row(&1))
    |> List.insert_at(0, titles)
  end

  def one_row(dadi) do
    [
      dadi |> post_date,
      #Todo Telephone
      dadi.title,
      dadi.content
    ]
  end

  def post_date(dadi) do
    date = dadi.post_date
           |> Timex.format("%m/%d/%Y", :strftime)

    case date do
      { :ok, f_date } -> f_date
      _ -> raise "Efl.Xls.Dadi post_date/1, parse date failly"
    end
  end

  def titles do
    [
      "发布日期",
      #"电话",
      "标题",
      "内容"
    ]
  end

  def file_name do
    date = TimeUtil.target_date
                |> Timex.format("%m-%d-%Y", :strftime)

    case date do
      { :ok, date } ->
        "分类抓取数据-" <> date <> ".xlsx"
      _ ->
        raise "Efl.Xls.Dadi create_xls/0 parse date failly"
    end
  end

  def available_dadis do
    query = from d in Dadi,
      where: (d.post_date == ^TimeUtil.target_date)

    RefCategory
    |> Repo.all
    |> Repo.preload(dadis: query)
  end
end
