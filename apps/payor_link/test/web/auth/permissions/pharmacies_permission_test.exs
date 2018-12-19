defmodule Innerpeace.PayorLink.Web.Permission.PharmacyTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Pharmacy Permission /pharmacies" do
    test "with manage_packages should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_pharmacies",
        module: "Pharmacies"
      })

      conn = get authenticated(conn, u), pharmacy_path(conn, :index)
      assert html_response(conn, 200) =~ "Pharmacies"
    end

    test "with access_packages should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_pharmacies",
        module: "Pharmacies"
      })

      conn = get authenticated(conn, u), pharmacy_path(conn, :index)
      assert html_response(conn, 200) =~ "Pharmacies"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), pharmacy_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
