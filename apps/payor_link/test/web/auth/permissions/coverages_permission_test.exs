defmodule Innerpeace.PayorLink.Web.Permission.CoverageTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Coverage Permission /coverages" do
    test "with manage_coverages should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_coverages",
        module: "Coverages"
      })

      conn = get authenticated(conn, u), coverage_path(conn, :index)
      assert html_response(conn, 200) =~ "Coverage"
    end

    test "with access_coverages should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_coverages",
        module: "Coverages"
      })

      conn = get authenticated(conn, u), coverage_path(conn, :index)
      assert html_response(conn, 200) =~ "Coverage"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), coverage_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
