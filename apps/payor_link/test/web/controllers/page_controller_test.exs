defmodule Innerpeace.PayorLink.Web.PageControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  import Innerpeace.PayorLink.TestHelper

  setup do
    conn = build_conn()
    user = insert(:user)
    conn = sign_in(conn, user)
    {:ok, %{conn: conn, user: user}}
  end

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Payor"
  end
end
