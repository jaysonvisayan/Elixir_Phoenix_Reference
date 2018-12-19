defmodule Innerpeace.PayorLink.Web.Permission.CaseRateTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Case Rate Permission /case_rates" do
    test "with manage_caserates should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_caserates",
        module: "CaseRates"
      })

      conn = get authenticated(conn, u), case_rate_path(conn, :index)
      assert html_response(conn, 200) =~ "Case Rate"
    end

    test "with access_benefits should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_caserates",
        module: "CaseRates"
      })

      conn = get authenticated(conn, u), case_rate_path(conn, :index)
      assert html_response(conn, 200) =~ "Case Rate"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), case_rate_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
