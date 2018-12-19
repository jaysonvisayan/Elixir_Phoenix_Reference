defmodule Innerpeace.PayorLink.Web.Permission.Main.UserTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end
  describe "User Permission /users" do
    test "with manage_users should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_users",
        module: "Users"
      })

      conn = get authenticated(conn, u), main_user_path(conn, :index)
      assert html_response(conn, 200) =~ "Users"
    end

    test "with access_users should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_users",
        module: "Users"
      })

      conn = get authenticated(conn, u), main_user_path(conn, :index)
      assert html_response(conn, 200) =~ "Users"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), main_user_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
