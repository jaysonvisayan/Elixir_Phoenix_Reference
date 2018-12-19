defmodule Innerpeace.PayorLink.Web.RoleView do
  use Innerpeace.PayorLink.Web, :view
  alias Innerpeace.Db.Base.{
    PermissionContext,
    RoleContext
  }

  def load_permissions(keyword) do
    PermissionContext.load_permission(keyword)
  end

  def load_role_permission(role_id, permission_id) do
    RoleContext.load_role_permissions(role_id, permission_id)
  end

  def load_all_permissions do
   PermissionContext.load_all_permission()
  end

end
