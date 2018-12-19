defmodule Innerpeace.PayorLink.Web.Main.RoleController do
  use Innerpeace.PayorLink.Web, :controller

  # alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    Role,
    RolePermission,
    RoleApplication
  }
  alias Innerpeace.Db.Base.{
    ApplicationContext,
    PermissionContext,
    RoleContext,
    CoverageContext
  }
  # plug :can_access?, %{permissions: ["manage_roles", "access_roles"]} when action in [:index]
  # plug :can_access?, %{permissions: ["manage_roles"]} when not action in [:index]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{roles: [:manage_roles]},
       %{roles: [:access_roles]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{roles: [:manage_roles]},
     ]] when not action in [
       :index,
       :show
     ]

  plug :map_applications when action in [:new, :create, :edit, :save]

  # plug :can_access?, %{permissions: ["manage_roles", "access_roles"]} when action in [:index]
  # plug :can_access?, %{permissions: ["manage_roles"]} when not action in [:index]

  plug :valid_uuid?, %{origin: "roles"}
  when not action in [:index]

  def index(conn, params) do
    roles = RoleContext.get_all_roles()
    render(conn, "index.html", roles: roles, swal: params["swal"])
  end

  def index(conn, _), do: render(conn, "index.html")

  def new(conn, _params) do
    coverages = CoverageContext.get_all_coverages()
    applications =  ApplicationContext.get_all_applications()
    application_ids = [] ++ for application <- applications do
      if application.name == "PayorLink" do
        application.id
      end
    end
    |> Enum.reject(&(&1 == nil))

    role = Map.put(%Role{}, :application_id, application_ids)
    permissions = PermissionContext.load_all_permission()
    changeset_permission = RoleContext.change_role_permission(%RolePermission{})
    changeset = Role.changeset_role(role)
    render(conn, "new.html", changeset: changeset, changeset_permission: changeset_permission, permissions: permissions, role: role, coverages: coverages, applications: applications)
  end

  def create(conn, %{"role" => role_params}) do
    user = conn.assigns.current_user
    if role_params["cut_off_dates"] == ["100"] || role_params["cut_off_dates"] == ["99"] do
      cut_off_date = []
    else
      cut_off_date = role_params["cut_off_dates"]
    end

    if role_params["no_of_days"] == "100" || role_params["no_of_days"] == "99" do
      no_of_days = 0
    else
      no_of_days = role_params["no_of_days"]
    end
    role_params =
      role_params
      |> Map.merge(%{"status" => "Active", "created_by_id" => conn.assigns.current_user.id})
      |> Map.put("cut_off_dates", cut_off_date)
      |> Map.put("no_of_days", no_of_days)
      |> Map.put("create_full_access", role_params["hidden_create_full_access"])

    role_params =
      if role_params["members_permissions"] == "member_permitted" do
        role_params
        |> Map.put("members_permissions", "")
        |> Map.put("member_permitted", true)
      else
        role_params
        |> Map.put("member_permitted", false)
      end

    role_params =
      if role_params["is_draft"] == "true" do
        role_params
        |> Map.put("status", "Draft")
      else
        role_params
      end

    application_id = [role_params["application_id"]]
    with {:ok, role} <- RoleContext.create_role_new(role_params),
         {:ok} <- RoleContext.create_role_application(role.id, application_id),
         {:ok} <- RoleContext.create_coverage_limit(role.id, role_params["approval_limit_amount"])
    do
      role_params
      |> Map.merge(%{"role_permission" => role.id})
      |> RoleContext.payor_modules()

      RoleContext.update_role_new(role, %{"updated_by_id" => user.id})
      RoleContext.clear_role_permission()

      if ApplicationContext.get_application(role_params["application_id"]).name == "ProviderLink",
      do: RoleContext.create_role_providerlink_api(role.id)

      if role_params["is_draft"] == "true" do
        conn
        |> put_flash(:info, "Role was successfully saved as draft!")
        |> redirect(to: "/web/roles")
      else
        conn
        # |> put_flash(:info, "Role created successfully!")
        |> redirect(to: "/web/roles?swal=true")
      end
      else
        # {:error, changeset} ->
        #   raise changeset
        _ ->
          conn
          |> put_flash(:error, "Error Adding Role.")
          |> redirect(to: main_role_path(conn, :new))
    end
  end

  def edit(conn, %{"id" => role_id}) do
    coverages = CoverageContext.get_all_coverages()
    role = RoleContext.get_role(role_id)
    application_ids = [] ++ for role_application <- role.role_applications do
      role_application.application.id
    end
    applications = Enum.map(role.role_applications, fn(x) ->
      x.application
    end)
    |> Enum.map(&{&1.name, &1.id})
    role = Map.put(role, :application_id, application_ids)
    changeset = Role.changeset_role(role)
    permissions = PermissionContext.load_all_permission()
    permission_checker = RoleContext.check_role_permission(role.id)

    if Enum.empty?(role.users) do
      render(conn, "edit.html", changeset: changeset, role: role, permissions: permissions, permission_checker: permission_checker, coverages: coverages, applications: applications)
    else
      conn
      |> put_flash(:error, "Role has been used")
      |> redirect(to: main_role_path(conn, :show, role.id))
    end
  end

  def save(conn, %{"id" => role_id, "role" => role_params}) do
    role = RoleContext.get_role(role_id)
    user = conn.assigns.current_user
    if role_params["cut_off_dates"] == ["99"] do
      cut_off_date = []
    else
      cut_off_date = role_params["cut_off_dates"]
    end

    if role_params["no_of_days"] == "99" || role_params["no_of_days"] == "0" do
      no_of_days = 0
    else
      no_of_days = role_params["no_of_days"]
    end

    role_params =
      if role_params["is_draft"] == "true" do
        role_params
        |> Map.put("status", "Draft")
      else
        role_params
        |> Map.put("status", "Active")
      end

    role_params =
      if role_params["members_permissions"] == "member_permitted" do
        role_params
        |> Map.put("members_permissions", nil)
        |> Map.put("member_permitted", true)
      else
        role_params
        |> Map.put("member_permitted", false)
      end

    role_params =
      role_params
      |> Map.put("updated_by_id", user.id)
      |> Map.put("cut_off_dates", cut_off_date)
      |> Map.put("no_of_days", no_of_days)
      |> Map.put("create_full_access", role_params["hidden_create_full_access"])

    application_id = [role_params["application_id"]]
    with {:ok, role} <- RoleContext.update_role_new(role, role_params),
         {:ok} <- RoleContext.create_role_application(role.id, application_id),
         {:ok} <- RoleContext.create_coverage_limit(role.id, role_params["approval_limit_amount"])
    do
      role_params
      |> Map.merge(%{"role_permission" => role.id})
      |> RoleContext.payor_modules()

      RoleContext.update_role_new(role, %{"updated_by_id" => user.id})
      RoleContext.clear_role_permission()

      if ApplicationContext.get_application(role_params["application_id"]).name == "ProviderLink",
      do: RoleContext.update_role_providerlink_api(role.id)

      get_role_status(conn, role.status, role.id)
    else
      _ ->
        conn
        |> put_flash(:error, "Error updating Role.")
        |> redirect(to: main_role_path(conn, :edit, role.id))
    end
  end

  defp get_role_status(conn, "Draft", id) do
    conn
    |> put_flash(:info, "Role was successfully saved as draft!")
    |> redirect(to: "/web/roles")
  end

  defp get_role_status(conn, "", id) do
    conn
    |> put_flash(:info, "Role updated successfully!")
    |> redirect(to: main_role_path(conn, :show, id))
  end

  defp get_role_status(conn, "Active", id) do
    conn
    |> put_flash(:info, "Role updated successfully!")
    |> redirect(to: main_role_path(conn, :show, id))
  end

  def show(conn, %{"id" => id}) do
    role = RoleContext.get_role(id)
    permissions = PermissionContext.load_all_permission()
    render(conn, "show.html", role: role, permissions: permissions)
  end

  #Private function
  defp map_applications(conn, _) do
    applications =
      ApplicationContext.get_all_applications()
      |> Enum.filter(fn(a) ->
        a.name == "PayorLink" or a.name == "ProviderLink"
      end)
      |> Enum.map(&{&1.name, &1.id})
    assign(conn, :applications, applications)
  end

  def load_all_roles(conn, _params) do
    roles = RoleContext.select_all_role_names()
    json conn, Poison.encode!(roles)
  end

  def role_checker(conn, %{"name" => name}) do
    role = RoleContext.get_role_by_name_for_checker(name)
    json conn, Poison.encode!(role)
  end

  def delete(conn, %{"id" => id}) do
    _role = RoleContext.get_role(id)
    RoleContext.clear_coverage_approval_limit_amount(id)
    {:ok, _role} = RoleContext.delete_role(id)
    conn
    |> put_flash(:info, "Role deleted successfully.")
    |> redirect(to: main_role_path(conn, :index))
  end

  def get_coverage_name(conn, _) do
    coverages = CoverageContext.get_all_coverage_name()
    json conn, Poison.encode!(coverages)
  end
end
