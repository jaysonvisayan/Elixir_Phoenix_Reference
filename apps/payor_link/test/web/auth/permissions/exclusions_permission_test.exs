defmodule Innerpeace.PayorLink.Web.Permission.ExclusionTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Exclusion Permission /exclusions" do
    test "with manage_exclusions should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_exclusions",
        module: "Exclusions"
      })

      conn = get authenticated(conn, u), exclusion_path(conn, :index)
      assert html_response(conn, 200) =~ "Exclusions"
    end

    test "with access_exclusions should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_exclusions",
        module: "Exclusions"
      })

      conn = get authenticated(conn, u), exclusion_path(conn, :index)
      assert html_response(conn, 200) =~ "Exclusions"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), exclusion_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
