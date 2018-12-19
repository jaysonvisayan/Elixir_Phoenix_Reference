defmodule Innerpeace.PayorLink.Web.Main.ExclusionControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
    alias Innerpeace.Db.Schemas.Exclusion
    alias Innerpeace.Db.Schemas.ExclusionCondition

    alias Ecto.UUID

    setup do
      conn = build_conn()
      user = fixture(:user_permission, %{keyword: "manage_exclusions", module: "Exclusions"})
      exclusion = insert(:exclusion, updated_by_id: user.id)
      conn = authenticated(conn, user)
      {:ok, %{conn: conn, user: user, exclusion: exclusion}}
    end

    describe "render form for" do
      test "index page", %{conn: conn} do
          conn = get(conn, main_exclusion_path(conn, :index))
          assert html_response(conn, 200)
      end
    end

  test "show exclusion", %{conn: conn, exclusion: exclusion} do
    conn = get conn, main_exclusion_path(conn, :show, exclusion.id)
    assert html_response(conn, 200) =~ "Exclusion"
  end

end
