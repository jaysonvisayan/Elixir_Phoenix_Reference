defmodule Innerpeace.PayorLink.Web.Permission.RoleTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Role Permission /roles" do
    test "with manage_roles should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_roles",
        module: "Roles"
      })

      conn = get authenticated(conn, u), role_path(conn, :index)
      assert html_response(conn, 200) =~ "Roles"
    end

    test "with access_roles should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_roles",
        module: "Roles"
      })

      conn = get authenticated(conn, u), role_path(conn, :index)
      assert html_response(conn, 200) =~ "Roles"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), role_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
