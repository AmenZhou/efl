defmodule Efl.PageControllerTest do
  use Efl.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    # The root path goes to DadiController, not PageController
    assert html_response(conn, 200) =~ "List"
  end
end
