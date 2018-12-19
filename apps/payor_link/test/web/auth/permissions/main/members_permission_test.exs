defmodule Innerpeace.PayorLink.Web.Permission.Main.MemberTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Member Permission /members" do
    test "with manage_members should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_members",
        module: "Members"
      })

      conn = get authenticated(conn, u), main_member_path(conn, :index)
      assert html_response(conn, 200) =~ "Member"
    end

    test "with access_members should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_members",
        module: "Members"
      })

      conn = get authenticated(conn, u), main_member_path(conn, :index)
      assert html_response(conn, 200) =~ "Member"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), main_member_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
