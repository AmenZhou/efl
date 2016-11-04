defmodule ClassificationUtility.Scratch do
  def html do
    case HTTPotion.get(url) do
      %{ body: body } ->
        { :ok, body }
      %{ message: message } ->
        { :error, message }
    end
  end

  def url do
    "http://c.dadi360.com/c/forums/show/53.page"
  end

  def items do
    case html do
      { :ok, html_body } ->
        html_body |> Floki.parse |> Floki.find(".bg_small_yellow")
    end
  end
end
