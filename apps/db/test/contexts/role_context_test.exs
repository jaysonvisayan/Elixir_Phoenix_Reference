defmodule Innerpeace.Db.Base.RoleContextTest do
  use Innerpeace.Db.SchemaCase
  use Innerpeace.Db.PayorRepo, :context
  alias Innerpeace.Db.Schemas.{
    Role

  }
  alias Innerpeace.Db.Repo

  @invalid_attrs %{}

  test "list all roles" do
    role = insert(:role, name: "test", step: "1")
    assert get_all_roles() == preload_roles([role])
  end

  test "get_role returns the role with given id" do
    role = insert(:role, name: "test", step: "1")
      |> Repo.preload([:users])
    assert get_role(role.id) == preload_roles(role)
  end

  test "create_role with valid data creates a role" do
    params = %{
      name: "test",
      description: "test",
      status: "test"
    }
    assert {:ok, %Role{} = role} = create_role(params)
    assert role.name == "test"
  end

  test "create_role with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = create_role(@invalid_attrs)
  end

  test "update_role with valid data updates the role" do
    role = insert(:role)
    params = %{
      name: "test1",
      description: "test",
      status: "test"
    }
    assert {:ok, role} = update_role(role.id, params)
    assert %Role{} = preload_roles(role)
    assert role.name == "test1"
  end

  test "update_role with invalid data returns error changeset" do
    role = :role
          |> insert(step: "1")
          |> preload_roles()
          |> Repo.preload([:users])

    assert {:error, %Ecto.Changeset{}} = update_role(role.id, @invalid_attrs)
    assert role == get_role(role.id)
  end

  test "delete_role deletes the role" do
    role = insert(:role)
    assert {:ok, %Role{}} = delete_role(role.id)
    assert_raise Ecto.NoResultsError, fn -> get_role(role.id) end
  end

  test "get_role_permission returns the role_permission with given id" do
    role = insert(:role, name: "test", step: "2")
    permission = insert(:permission, name: "asd")
    role_permission = insert(:role_permission, role: role, permission: permission)
    assert get_role_permission(role.id) == role_permission
  end

  test "create_role_permission with valid data creates a role_permission" do
    role = insert(:role, name: "test")
    permission = insert(:permission, name: "permission_test")
    assert role_permission = create_role_permissions(role.id, [permission.id])
    assert Enum.empty?(role_permission) == false
  end

  test "change_role/1 returns a role changeset" do
    role = insert(:role, name: "name")
    assert %Ecto.Changeset{} = change_role(role)
  end

  test "add_created_by/2 returns the params" do
    role = insert(:role, status: "submitted")
    user = insert(:user, username: "testuser")
    params = %{"updated_by_id" => user.id}
    assert add_created_by(role, user.id) == params
  end

  test "create_role_application with valid data create a role_application" do
    role = insert(:role, name: "test")
    application = insert(:application, name: "application_test")
    assert ok = create_role_application(role.id, [application.id])
    assert ok == {:ok}
  end

  defp preload_roles(role) do
    role
    |> Repo.preload([
      :created_by, :updated_by,
      [role_applications: :application],
      [role_permissions: :permission],
      [coverage_approval_limit_amounts: :coverage]])
  end

end

