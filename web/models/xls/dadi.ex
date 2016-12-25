defmodule Efl.Xls.Dadi do
  require Elixlsx

  alias Elixlsx.Sheet
  alias Elixlsx.Workbook
  alias Efl.Repo
  alias Efl.RefCategory
  import Ecto.Query
  use Timex

  def create_xls do
    %Workbook{sheets: sheets}
    |> Elixlsx.write_to(file_name)
  end

  def sheets do
    cat = RefCategory
    |> first
    |> Repo.one
    |> Repo.preload(:dadis) 

    [cat]
    |> Enum.map(&one_sheet(&1))
  end

  def one_sheet(ref_category) do
    %Sheet{
      name: ref_category.name,
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
    today_date = Timex.now
                 |> Timex.format("%m-%d-%Y", :strftime)

    case today_date do
      { :ok, today_date } ->
        "分类抓取数据-" <> today_date <> ".xlsx"
      _ ->
        raise "Efl.Xls.Dadi create_xls/0 parse date failly"
    end
  end
end
