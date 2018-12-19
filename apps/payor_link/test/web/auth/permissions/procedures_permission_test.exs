defmodule Innerpeace.PayorLink.Web.Permission.ProcedureTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Procedure Permission /procedures" do
    test "with manage_procedures should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_procedures",
        module: "Procedures"
      })

      conn = get authenticated(conn, u), procedure_path(conn, :index)
      assert html_response(conn, 200) =~ "Procedures"
    end

    test "with access_procedures should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_procedures",
        module: "Procedures"
      })

      conn = get authenticated(conn, u), procedure_path(conn, :index)
      assert html_response(conn, 200) =~ "Procedures"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), procedure_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
