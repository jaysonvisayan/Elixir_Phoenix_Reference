defmodule AuthWeb.PageControllerTest do
  use AuthWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/", consent: "dfad"
    assert html_response(conn, 200) =~ "Login"
  end
end
