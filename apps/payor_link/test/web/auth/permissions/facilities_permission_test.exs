defmodule Innerpeace.PayorLink.Web.Permission.FacilityTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Facility Permission /facilities" do
    test "with manage_facilities should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_facilities",
        module: "Facilities"
      })

      conn = get authenticated(conn, u), facility_path(conn, :index)
      assert html_response(conn, 200) =~ "Facilities"
    end

    test "with access_facilities should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_facilities",
        module: "Facilities"
      })

      conn = get authenticated(conn, u), facility_path(conn, :index)
      assert html_response(conn, 200) =~ "Facilities"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), facility_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
