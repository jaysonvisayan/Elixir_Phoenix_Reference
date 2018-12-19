defmodule Innerpeace.PayorLink.Web.Permission.Main.AcuScheduleTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # alias Innerpeace.Db.Schemas.User
  # alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  describe "Acu Schedule Permission /web/acu_schedules" do
    test "with manage_products should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "manage_acu_schedules",
        module: "Acu_Schedules"
      })

      conn = get authenticated(conn, u), main_acu_schedule_path(conn, :index)
      assert html_response(conn, 200) =~ "Acu"
    end

    test "with access_products should have access to index", %{conn: conn} do
      u = fixture(:user_permission, %{
        keyword: "access_acu_schedules",
        module: "Acu_Schedules"
      })

      conn = get authenticated(conn, u), main_acu_schedule_path(conn, :index)
      assert html_response(conn, 200) =~ "Acu"
    end

    # test "without access", %{conn: conn} do
    #   u = fixture(:user_permission, %{
    #     keyword: "",
    #     module: ""
    #   })

    #   conn = get authenticated(conn, u), main_acu_schedule_path(conn, :index)

    #   assert redirected_to(conn, 302) == "/"
    # end
  end
end
