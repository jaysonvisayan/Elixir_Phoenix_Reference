# defmodule Innerpeace.PayorLink.Web.Main.RoleControllerTest do
#   use Innerpeace.PayorLink.Web.ConnCase
#   # import Innerpeace.PayorLink.TestHelper
#   use Innerpeace.Db.PayorRepo, :context
#   alias Innerpeace.Db.Repo

#   setup do
#     conn = build_conn()
#     user = fixture(:user_permission, %{keyword: "manage_roles", module: "Roles"})
#            |> Repo.preload([user_roles: [role:
#                                          [[role_permissions: :permission],
#                                          [role_applications: :application]
#            ]]])
#     conn = authenticated(conn, user)
#     application = insert(:application, name: "test")
#     user_roles = user.user_roles
#     roles = Enum.map(user_roles, fn(x) ->
#       x.role
#     end)
#     role = roles
#            |> List.first()
#     permissions = Enum.map(role.role_permissions, fn(x) ->
#       x.permission
#     end)
#     permission = permissions
#                  |> List.first()
#     {:ok, %{conn: conn, user: user, application: application, role: role, permission: permission}}
#   end

#   @create_attrs %{name: "test123", description: "test", status: "asda"}
#   @update_attrs %{name: "test1", description: "test1", status: "asda1"}
#   @invalid_attrs %{name: nil}
