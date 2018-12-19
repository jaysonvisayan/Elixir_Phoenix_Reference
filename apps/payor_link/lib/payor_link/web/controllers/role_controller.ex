defmodule Innerpeace.PayorLink.Web.RoleController do
  use Innerpeace.PayorLink.Web, :controller

  # alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    Role,
    RolePermission
  }
  alias Innerpeace.Db.Base.{
    ApplicationContext,
    PermissionContext,
    RoleContext,
    CoverageContext
  }

  plug :map_applications when action in [:new, :create, :setup, :update_setup, :step_1, :update]

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

  plug :valid_uuid?, %{origin: "roles"}
  when not action in [:index]

  def index(conn, _params) do
    roles =  RoleContext.get_all_roles()
    render(conn, "index.html", roles: roles)
  end

  def new(conn, _params) do
    applications =  ApplicationContext.get_all_applications()
    application_ids = [] ++ for application <- applications do
      if application.name == "PayorLink" do
        application.id
      end
    end
    role = Map.put(%Role{}, :application_ids, application_ids)
    changeset = RoleContext.change_role(role)
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"role" => role_params}) do
    role_params =
      role_params
      |> Map.merge(%{"status" => "Pending", "step" => 2, "created_by_id" => conn.assigns.current_user.id})
    case RoleContext.create_role(role_params) do
      {:ok, role} ->
        if role_params["application_ids"] == nil do
          conn
          |> put_flash(:error, "No Applications selected")
          |> redirect(to: "/roles/#{role.id}/setup?step=1")
        else
        RoleContext.create_role_application(role.id, role_params["application_ids"])
        conn
          |> put_flash(:info, "Basic info added successfully.")
          |> redirect(to: "/roles/#{role.id}/setup?step=2")
        end
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error creating role! Please check the errors below.")
        |> render("new.html", changeset: changeset)
    end
  end

  def setup(conn, %{"step" => step, "id" => id}) do
    role = RoleContext.get_role(id)
    validate_step(conn, role, step)
    case step do
      "1" ->
        step_1(conn, role)
      "2" ->
        step_2(conn, role)
      "3" ->
        step_3(conn, role)
      _ ->
        conn
        |> redirect(to: role_path(conn, :index))
    end
  end

  def setup(conn, %{"id" => id}) do
    conn
    |> put_flash(:error, "Invalid URL")
    |> redirect(to: role_path(conn, :index))
  end

  def update_setup(conn, %{"id" => id, "step" => step, "role" => role_params}) do
    role = RoleContext.get_role(id)
    case step do
      "1" ->
        update(conn, role, role_params)
      "2" ->
        create_role_permission(conn, role, role_params)
      "3" ->
        create_summary(conn, role)
    end
  end

  def validate_step(conn, role, step) do
    if role.step < String.to_integer(step) do
      conn
      |> put_flash(:error, "Not allowed!")
      |> redirect(to: role_path(conn, :index))
    end
  end

  def show(conn, %{"id" => id}) do
    role = RoleContext.get_role(id)
    permissions = PermissionContext.load_all_permission()
    render(conn, "show.html", role: role, permissions: permissions)
  end

   def step_1(conn, role) do
    _applications =  ApplicationContext.get_all_applications()
    application_ids = [] ++ for role_application <- role.role_applications do
      role_application.application.id
    end
    role = Map.put(role, :application_ids, application_ids)
    changeset = RoleContext.change_role(role)
    render(conn, "edit.html", role: role, changeset: changeset)
  end

  def update(conn, role, role_params) do
    role_params =
      role_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
    case RoleContext.update_role(role.id, role_params) do
      {:ok, role} ->
        if role_params["application_ids"] == nil do
          conn
          |> put_flash(:error, "No Applications selected")
          |> redirect(to: "/roles/#{role.id}/setup?step=1")
        else
        RoleContext.create_role_application(role.id, role_params["application_ids"])
        conn
          |> put_flash(:info, "Basic info added successfully.")
          |> redirect(to: "/roles/#{role.id}/setup?step=2")
        end
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error creating user! Please check the errors below.")
        |> render("edit.html", role: role, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    _role = RoleContext.get_role(id)
    {:ok, _role} = RoleContext.delete_role(id)
    conn
    |> put_flash(:info, "Role deleted successfully.")
    |> redirect(to: role_path(conn, :index))
  end

  def step_2(conn, role) do
    permissions = PermissionContext.load_all_permission()
    changeset = RoleContext.change_role_permission(%RolePermission{})
    permission_checker = RoleContext.check_role_permission(role.id)
    render(conn, "new-permission.html", role: role, changeset: changeset, permissions: permissions, permission_checker: permission_checker)
  end

  def create_role_permission(conn, role, role_params) do
    #raise role_params
    user = conn.assigns.current_user.id
    role_params
    |> Map.merge(%{"role_permission" => role.id})
    |> RoleContext.payor_modules()
    _permissions = PermissionContext.get_all_permissions()
    changeset = RolePermission.virtual_changeset(%RolePermission{}, role_params)
    if changeset do
      if role.step == 4 do
        RoleContext.update_role(role.id, %{"updated_by_id" => user, "approval_limit" => role_params["approval_limit"]})
        RoleContext.clear_role_permission()
        conn
        |> put_flash(:info, "Permissions added to role successfully.")
        |> redirect(to: role_path(conn, :show, role))
      else
        RoleContext.update_role(role.id, %{"step" => 3, "approval_limit" => role_params["approval_limit"]})
        RoleContext.clear_role_permission()
        conn
        |> put_flash(:info, "Permissions added to role successfully.")
        |> redirect(to: "/roles/#{role.id}/setup?step=3")
      end
    else
      conn
      |> put_flash(:error, "No Permissions selected")
      |> redirect(to: "/roles/#{role.id}/setup?step=2")
    end
  end

  def step_3(conn, role) do
    permissions = PermissionContext.load_all_permission()
    changeset = RoleContext.change_role(role)
    render(conn, "summary.html", changeset: changeset, role: role, permissions: permissions)
  end

  def create_summary(conn, role) do
    user = conn.assigns.current_user.id
    role_params = role |> RoleContext.add_created_by(user) |> Map.merge(%{"step" => 4})
    case RoleContext.update_role(role.id, role_params) do
      {:ok, _role} ->
        conn
        |> put_flash(:info, "Role created successfully.")
        |> redirect(to: role_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new-summary.html", changeset: changeset)
    end
  end

  #Private function
  defp map_applications(conn, _) do
    applications =
      ApplicationContext.get_all_applications()
      |> Enum.map(&{&1.name, &1.id})
    assign(conn, :applications, applications)
  end

  def load_all_roles(conn, _params) do
    roles = RoleContext.select_all_role_names()
    json conn, Poison.encode!(roles)
  end

  def get_coverage_name(conn, _) do
    coverages = CoverageContext.get_all_coverage_name()
    json conn, Poison.encode!(coverages)
  end
end
