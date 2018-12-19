defmodule Innerpeace.PayorLink.Web.Permission.DiseaseTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Disease Permission /diseases" do
    test "with manage_diseases should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_diseases",
        module: "Diseases"
      })

      conn = get authenticated(conn, u), diagnosis_path(conn, :index)
      assert html_response(conn, 200) =~ "Diseases"
    end

    test "with access_diseases should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_diseases",
        module: "Diseases"
      })

      conn = get authenticated(conn, u), diagnosis_path(conn, :index)
      assert html_response(conn, 200) =~ "Diseases"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), diagnosis_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
