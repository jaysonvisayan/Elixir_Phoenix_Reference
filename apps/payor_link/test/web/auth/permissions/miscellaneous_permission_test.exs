defmodule Innerpeace.PayorLink.Web.Permission.MiscellaneousTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Miscellaneous Permission /miscellaneous" do
    test "with manage_miscellaneous should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_miscellaneous",
        module: "Miscellaneous"
      })

      conn = get authenticated(conn, u), miscellaneous_path(conn, :index)
      assert html_response(conn, 200) =~ "Misc"
    end

    test "with access_miscellaneous should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_miscellaneous",
        module: "Miscellaneous"
      })

      conn = get authenticated(conn, u), miscellaneous_path(conn, :index)
      assert html_response(conn, 200) =~ "Misc"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), miscellaneous_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
