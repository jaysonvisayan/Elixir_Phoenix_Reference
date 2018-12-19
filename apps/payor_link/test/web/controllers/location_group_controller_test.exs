defmodule Innerpeace.PayorLink.Web.LocationGroupControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper

  setup do
    conn = build_conn()
    user = fixture(:user_permission, %{keyword: "manage_location_groups", module: "Location_Groups"})
    conn = authenticated(conn, user)
    location_group = insert(:location_group,
                            name: "test location group",
                            code: "test code",
                            created_by_id: user.id,
                            updated_by_id: user.id,
                            description: "Test"
    )
    # conn = sign_in(conn, user)
    {:ok, %{conn: conn, location_group: location_group}}
  end

  # test "new/2, renders form for creating new location group", %{conn: conn} do
  #   conn = get conn, location_group_path(conn, :new)
  #   assert html_response(conn, 200) =~ "Location Group"
  # end

  # test "index/2, lists all entries on index", %{conn: conn, location_group: location_group} do
  #   conn = get conn, location_group_path(conn, :index)
  #   assert html_response(conn, 200) =~ "Location Group"
  #   assert html_response(conn, 200) =~ location_group.code
  # end

  # test "create_general/2, creates location group with valid attributes and proceeds to step2", %{conn: conn} do
  #   params = %{
  #     "name" => "test name",
  #     "description" => "test description"
  #   }
  #   conn = post conn,  location_group_path(conn, :new), location_group: params
  #   assert %{id: id} = redirected_params(conn)
  #   assert redirected_to(conn) == location_group_path(conn, :setup, id, step: "2")
  # end

  # test "create_general/2, creates location group with invalid attributes", %{conn: conn} do
  #   params = %{
  #     "name" => nil,
  #     "description" => "test description"
  #   }
  #   conn = post conn, location_group_path(conn, :new), location_group: params
  #    assert html_response(conn, 200) =~ "Location Group Name"
  # end

  #  test "update_general/2, updates a location group with valid attributes", %{conn: conn} do
  #     params = %{
  #     "name" => "test name",
  #     "description" => "test description"
  #   }
  #   conn = post conn,  location_group_path(conn, :new), location_group: params
  #   assert %{id: id} = redirected_params(conn)
  #   assert redirected_to(conn) == location_group_path(conn, :setup, id, step: "2")
  #  end

  #  test "update_general/2, updates a location group with invalid attributes", %{conn: conn} do
  #   params = %{
  #     "name" => nil,
  #     "description" => "test description"
  #   }
  #   conn = post conn, location_group_path(conn, :new), location_group: params
  #    assert html_response(conn, 200) =~ "Location Group Name"
  #  end

  #  test "setup/2, redirect to step2 when data is valid", %{conn: conn} do
  #      params = %{
  #     "name" => "test name",
  #     "description" => "test description"
  #   }
  #   conn = post conn, location_group_path(conn, :new), location_group: params
  #   assert %{id: id} = redirected_params(conn)
  #   assert redirected_to(conn) == location_group_path(conn, :setup, id, step: "2")
  #  end

  #  test "submit_location_group/2, submit a location group with valid attributes", %{conn: conn, location_group: location_group} do
  #   conn = put conn, location_group_path(conn, :submit_location_group, location_group.id)
  #   assert redirected_to(conn) == "/location_groups"
  #  end

  #  test "show_summary/2", %{conn: conn, location_group: location_group} do
  #    conn = get conn, location_group_path(conn, :show_summary, location_group.id)
  #    assert html_response(conn, 200) =~ "Luzon"
  #  end

  #  test "delete_lg/2, deletes a created location group draft", %{conn: conn, location_group: location_group} do
  #    conn = delete conn, location_group_path(conn, :delete_lg, location_group.id)
  #    assert json_response(conn, 200) == "success"
  #  end

  # test "show", %{conn: conn, location_group: location_group} do
  #    conn = get conn, location_group_path(conn, :show, location_group.id)
  #    assert html_response(conn, 200) =~ "Luzon"
  #  end

end
