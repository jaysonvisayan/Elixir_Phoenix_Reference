defmodule Innerpeace.PayorLink.Web.Permission.RuvTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "RUV Permission /ruvs" do
    test "with manage_ruvs should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_ruvs",
        module: "RUVs"
      })

      conn = get authenticated(conn, u), ruv_path(conn, :index)
      assert html_response(conn, 200) =~ "RUVs"
    end

    test "with access_ruvs should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_ruvs",
        module: "RUVs"
      })

      conn = get authenticated(conn, u), ruv_path(conn, :index)
      assert html_response(conn, 200) =~ "RUVs"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), ruv_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
