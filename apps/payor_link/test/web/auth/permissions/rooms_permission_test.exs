defmodule Innerpeace.PayorLink.Web.Permission.RoomTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Room Permission /rooms" do
    test "with manage_rooms should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_rooms",
        module: "Rooms"
      })

      conn = get authenticated(conn, u), room_path(conn, :index)
      assert html_response(conn, 200) =~ "Rooms"
    end

    test "with access_rooms should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_rooms",
        module: "Rooms"
      })

      conn = get authenticated(conn, u), room_path(conn, :index)
      assert html_response(conn, 200) =~ "Rooms"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), room_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
