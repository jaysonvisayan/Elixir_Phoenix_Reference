defmodule Innerpeace.PayorLink.Web.Permission.CompanyTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Company Permission /companies" do
    test "with manage_companies should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_company",
        module: "Company"
      })

      conn = get authenticated(conn, u), company_path(conn, :index)
      assert html_response(conn, 200) =~ "Company"
    end

    test "with access_companies should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_company",
        module: "Company"
      })

      conn = get authenticated(conn, u), company_path(conn, :index)
      assert html_response(conn, 200) =~ "Company"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), company_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
