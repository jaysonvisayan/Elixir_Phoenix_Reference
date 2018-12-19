defmodule Innerpeace.PayorLink.Web.RoleControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper
  use Innerpeace.Db.PayorRepo, :context
  alias Innerpeace.Db.Repo

  setup do
    conn = build_conn()
    user = fixture(:user_permission, %{keyword: "manage_roles", module: "Roles"})
           |> Repo.preload([user_roles: [role:
                                         [[role_permissions: :permission],
                                         [role_applications: :application]
           ]]])
    conn = authenticated(conn, user)
    application = insert(:application, name: "test")
    user_roles = user.user_roles
    roles = Enum.map(user_roles, fn(x) ->
      x.role
    end)
    role = roles
           |> List.first()
    permissions = Enum.map(role.role_permissions, fn(x) ->
      x.permission
    end)
    permission = permissions
                 |> List.first()
    {:ok, %{conn: conn, user: user, application: application, role: role, permission: permission}}
  end

  @create_attrs %{name: "test123", description: "test", status: "asda"}
  @update_attrs %{name: "test1", description: "test1", status: "asda1"}
  @invalid_attrs %{name: nil}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, role_path(conn, :index)
    assert html_response(conn, 200) =~ "Role"
  end

  test "renders form for new roles", %{conn: conn} do
    conn = get conn, role_path(conn, :new)
    assert html_response(conn, 200) =~ "Basic"
  end

  test "creates new role and redirects to step 2 when data is valid", %{conn: conn, application: application} do
    params = Map.merge(@create_attrs , %{"application_ids" => [application.id]})
    conn = post conn, role_path(conn, :create), role: params
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == role_path(conn, :setup, id, step: "2")
  end

  test "does not create role and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, role_path(conn, :create), role: @invalid_attrs
    assert html_response(conn, 200) =~ "Basic"
  end

  test "updates chosen role and redirects to step 2 when data is valid", %{conn: conn, role: role, application: application} do
    params = Map.merge(@update_attrs , %{"application_ids" => [application.id]})
    conn = put conn, role_path(conn, :update_setup, role, step: "1"), role: params
    assert redirected_to(conn) == role_path(conn, :setup, role, step: "2")
  end

  test "does not update chosen role and renders errors when data is invalid", %{conn: conn, role: role} do
    conn = put conn, role_path(conn, :update_setup, role, step: "1"), role: @invalid_attrs
    assert html_response(conn, 200) =~ "Basic"
  end

  test "renders form for permission - step 2", %{conn: conn, role: role} do
    conn = get conn, role_path(conn, :setup, role, step: "2")
    assert html_response(conn, 200) =~ "Permission"
  end

  test "adds permission and redirects to step 3 when data is valid", %{conn: conn, role: role, permission: permission} do
    conn = put conn, role_path(conn, :update_setup, role, step: "2"),
    role: %{role_id: role.id, permission_id: [permission.id]}
    assert redirected_to(conn) == role_path(conn, :setup, role, step: "3")
  end

  test "does not redirect to next step when no permission selected", %{conn: conn, role: role} do
    conn = put conn, role_path(conn, :update_setup, role, step: "2"),
    role: %{"account_permissions" => role.id}
    assert redirected_to(conn) == role_path(conn, :setup, role, step: "3")
  end

  test "renders review page - step 3", %{conn: conn, role: role} do
    conn = get conn, role_path(conn, :setup, role, step: "3")
    assert html_response(conn, 200) =~ "Role"
  end

  test "successfully creates role and redirects to index page", %{conn: conn, user: user, role: role} do
    params = Map.merge(@update_attrs, %{
      "created_by" => user.id,
      "status" => "submitted",
      "updated_by" => user.id,
      "step" => 4
    })
    conn = put conn, role_path(conn, :update_setup, role, step: "3"), role: params
    assert redirected_to(conn) == role_path(conn, :index)
  end

  test "renders form for editing chosen role - step 1", %{conn: conn, role: role} do
    conn = get conn, role_path(conn, :setup, role, step: "1")
    assert html_response(conn, 200) =~ "Role"
  end

  test "deletes chosen role", %{conn: conn, role: role} do
    conn = delete conn, role_path(conn, :delete, role)
    assert redirected_to(conn) == role_path(conn, :index)
    assert_error_sent 404, fn ->
      get conn, role_path(conn, :show, role)
    end
  end

  test "ajax role validations", %{conn: conn, role: role} do
    conn = get conn, role_path(conn, :load_all_roles)
    params = Poison.encode!([%{name: role.name}])
    assert Poison.decode!(conn.resp_body) == "#{params}"
    assert conn.status == 200
  end

end
