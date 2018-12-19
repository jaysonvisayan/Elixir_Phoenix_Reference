defmodule Innerpeace.PayorLink.Web.Permission.LocationGroupTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Location Group Permission /location_groups" do
    test "with manage_location_groups should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_location_groups",
        module: "Location_Groups"
      })

      conn = get authenticated(conn, u), location_group_path(conn, :index)
      assert html_response(conn, 200) =~ "Location"
    end

    test "with access_facilities should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_location_groups",
        module: "Location_Groups"
      })

      conn = get authenticated(conn, u), location_group_path(conn, :index)
      assert html_response(conn, 200) =~ "Location Group"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), location_group_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
