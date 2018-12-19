defmodule Innerpeace.Db.Base.PermissionContext do
  @moduledoc false

  alias Innerpeace.Db.{
    Repo,
    Schemas.Permission,
    Schemas.RolePermission
  }
  import Ecto.Query

  def insert_or_update_permission(params) do
    permission = get_permission_by_name(params.name, params.keyword)
    if is_nil(permission) do
      create_permission(params)
    else
      update_permission(permission.id, params)
    end
  end

  def get_permission_by_name(name, keyword) do
    Permission
    |> Repo.get_by(name: name, keyword: keyword)
  end

  def get_all_permissions do
    Permission
    |> Repo.all()
  end

  def get_permission(id) do
    Permission
    |> Repo.get!(id)
  end

  def create_permission(permission_param) do
    %Permission{}
    |> Permission.changeset(permission_param)
    |> Repo.insert
  end

  def update_permission(id, permission_param) do
    id
    |> get_permission()
    |> Permission.changeset(permission_param)
    |> Repo.update
  end

  def delete_permission(id) do
    id
    |> get_permission()
    |> Repo.delete
  end

  def load_all_permission do
    Permission
    |> where([p], like(p.keyword, ^"%manage%"))
    |> order_by([p], asc: p.keyword)
    |> Repo.all()
  end

  def load_permission(keyword) do
    Permission
    |> where([p], p.keyword == ^keyword)
    |> Repo.all
  end

  def get_permission_by_keyword(keyword) do
    Permission
    |> where([p], p.keyword == ^keyword)
    |> select([p], p.id)
    |> Repo.one()
  end

  def get_permission_access_by_module(module, name) do
    Permission
    |> where([p], p.module == ^module and p.name == ^name)
    |> select([p], p.keyword)
    |> Repo.one()
  end
end
