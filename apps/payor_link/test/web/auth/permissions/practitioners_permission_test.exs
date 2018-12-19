defmodule Innerpeace.PayorLink.Web.Permission.PractitionerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Practitioner Permission /practitioners" do
    test "with manage_practitioners should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_practitioners",
        module: "Practitioners"
      })

      conn = get authenticated(conn, u), practitioner_path(conn, :index)
      assert html_response(conn, 200) =~ "Practitioners"
    end

    test "with access_practitioners should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_practitioners",
        module: "Practitioners"
      })

      conn = get authenticated(conn, u), practitioner_path(conn, :index)
      assert html_response(conn, 200) =~ "Practitioners"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), practitioner_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
