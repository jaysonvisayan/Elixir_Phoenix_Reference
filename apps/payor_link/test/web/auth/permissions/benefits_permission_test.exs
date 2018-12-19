defmodule Innerpeace.PayorLink.Web.Permission.BenefitTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Benefit Permission /benefits" do
    test "with manage_benefits should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_benefits",
        module: "Benefits"
      })

      conn = get authenticated(conn, u), benefit_path(conn, :index)
      assert html_response(conn, 200) =~ "Benefit"
    end

    test "with access_benefits should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_benefits",
        module: "Benefits"
      })

      conn = get authenticated(conn, u), benefit_path(conn, :index)
      assert html_response(conn, 200) =~ "Benefit"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), benefit_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
