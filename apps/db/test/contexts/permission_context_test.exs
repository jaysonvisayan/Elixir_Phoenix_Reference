defmodule Innerpeace.Db.Base.PermissionContextTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.Permission
  alias Innerpeace.Db.Base.PermissionContext

  @invalid_attrs %{}

  test "lists all permissions" do
    permission = insert(:permission, name: "test")
    assert PermissionContext.get_all_permissions() == [permission]
  end

  test "get_permission returns the permission with given id" do
    permission = insert(:permission, name: "test")
    assert PermissionContext.get_permission(permission.id) == permission
  end

  test "create_permission with valid data creates a permission" do
    application = insert(:application)
    params = %{
      name: "test",
      description: "test",
      status: "test",
      module: "test",
      keyword: "test",
      application_id: application.id
    }
    assert {:ok, %Permission{} = permission} = PermissionContext.create_permission(params)
    assert permission.name == "test"
  end

  test "create_permission with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = PermissionContext.create_permission(@invalid_attrs)
  end

  test "update_permission with valid data updates the permission" do
    application = insert(:application)
    permission = insert(:permission)
    params = %{
      name: "test1",
      description: "test",
      status: "test",
      module: "test",
      keyword: "test",
      application_id: application.id
    }
    assert {:ok, permission} = PermissionContext.update_permission(permission.id, params)
    assert %Permission{} = permission
    assert permission.name == "test1"
  end

  test "update_permission with invalid data returns error changeset" do
    permission = insert(:permission)
    assert {:error, %Ecto.Changeset{}} = PermissionContext.update_permission(permission.id, @invalid_attrs)
    assert permission == PermissionContext.get_permission(permission.id)
  end

  test "delete_permission deletes the permission" do
    permission = insert(:permission)
    assert {:ok, %Permission{}} = PermissionContext.delete_permission(permission.id)
    assert_raise Ecto.NoResultsError, fn -> PermissionContext.get_permission(permission.id) end
  end

end
