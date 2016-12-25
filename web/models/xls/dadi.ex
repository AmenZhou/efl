defmodule Efl.Xls.Dadi do
  require Elixlsx

  alias Elixlsx.Sheet
  alias Elixlsx.Workbook
  alias Efl.Repo
  alias Efl.Dadi.Main, as: Dadi

  def create_xls do
    Dadi
    |> Repo.all
    |> Enum.each(fn(d) ->
      
    end)
    #sheet2 = %Sheet{name: 'Third', rows: [[1,2,3,4,5],
      #[1,2],
      #["increased row height"],
      #["hello", "world"]]}
  #Sheet.set_row_height(3, 40)

  #workbook = Workbook.append_sheet(workbook, sheet2)
  #Elixlsx.write_to("empty.xlsx")
  end
end
