defmodule Innerpeace.PayorLink.Web.Main.UserController do
  use Innerpeace.PayorLink.Web, :controller
  use Innerpeace.Db.PayorRepo, :context

  alias Innerpeace.Db.Schemas.{
    User,
  }

  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Base.{
    UserContext,
    ApplicationContext,
    RoleContext,
    CompanyContext,
    Api.UtilityContext,
    CoverageContext,
    FacilityContext,
  }
  alias Innerpeace.Db.Utilities.SMS
  alias Innerpeace.Db.Datatables.UserDatatable, as: UDT

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{users: [:manage_users]},
       %{users: [:access_users]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{users: [:manage_users]},
     ]] when not action in [
       :index,
       :show,
       :index_data,
       :get_company_users
     ]

  def index(conn, _params) do
    pem = conn.private.guardian_default_claims["pem"]["users"]
    users = UDT.list_users()
    render(conn, "index.html", users: users, permission: pem)
  end

  def new(conn, _params) do
    changeset = User.changeset2(%User{})
    roles = RoleContext.get_all_roles()
    companies = CompanyContext.list_all_companies()
    render(
      conn,
      "new.html",
      changeset: changeset,
      roles: roles,
      companies: companies,
      modal_result: false
    )
  end

  def create(conn, %{"user" => user_params}) do
    user_params = user_params |> setup_mobile_params() |> add_updated_by(conn.assigns)
    companies = CompanyContext.list_all_companies()
    roles = RoleContext.get_all_roles()
    with {:ok, user} <- UserContext.create_user2(user_params) do
      UserContext.set_user_roles(user.id, [user_params["role_id"]])
      UserContext.insert_reporting_to(user.id, user_params["reporting_to"])
      user_with_pass = UserContext.generate_temp_password(user)

      user_roles =
        user_with_pass.roles
        |> List.first()

      role_application =
        user_roles.role_applications
        |> List.first()

      application = role_application.application.name

      if application == "ProviderLink" do
        UserContext.match_user_providerlink_api(user_with_pass, user_params["role_id"], "insert")
      end

      changeset = %User{} |> User.changeset2(user_params)
      # redirect(conn, to: main_user_path(conn, :show, user))
      render(
        conn,
        "new.html",
        changeset: changeset,
        roles: roles,
        companies: companies,
        modal_result: true
      )
    else
      {:error, changeset} ->
        render(
          conn,
          "new.html",
          changeset: changeset,
          roles: roles,
          companies: companies,
          modal_result: false
        )
    end
  end

  def load_facilities(conn, _) do
    facilities = FacilityContext.facility_dropdown()

    conn
    |> json(%{success: true, results: facilities})
  end

  defp add_updated_by(params, conn) do
    with true <- Map.has_key?(conn, :current_user) do
      params
      |> Map.put("updated_by_id", conn.current_user.id)
    else
      _ ->
        params
    end
  end

  defp setup_mobile_params(params) do
    with true <- Map.has_key?(params, "mobile") do
      number =
        params["mobile"]
        |> String.replace("-", "")
      params
      |> Map.put("mobile", number)
      |> Map.put("status", "Active")
    else
      _ ->
        params
    end
  end

  def edit(conn, %{"id" => user_id}) do
    user = get_user!(user_id)
    changeset = User.changeset2(user)
    roles = RoleContext.get_all_roles()
    companies = CompanyContext.list_all_companies()
    render(
      conn,
      "edit.html",
      changeset: changeset,
      roles: roles,
      user: user,
      companies: companies
    )
  end

  def save(conn, %{"id" => user_id, "user" => user_params}) do
    user_params =
      user_params
      |> Map.put_new("acu_schedule_notification", false)

    user = get_user!(user_id)
    roles = RoleContext.get_all_roles()
    companies = CompanyContext.list_all_companies()

    user_params = add_updated_by(user_params, conn.assigns)
    with {:ok, user} <- UserContext.update_user2(user, user_params) do
      UserContext.clear_user_roles(user.id)
      UserContext.set_user_roles(user.id, [user_params["role_id"]])
      UserContext.clear_user_reporting_to(user.id)
      UserContext.insert_reporting_to(user.id, user_params["reporting_to"])

      user =
        user
        |> UserContext.preload_facility()
        |> UserContext.preload_user_roles()

      user_roles =
        user.roles
        |> List.first()

      if !is_nil(user_roles) do
        role_application =
          user_roles.role_applications
          |> List.first()

        application = role_application.application.name

        if application == "ProviderLink" do
          UserContext.match_user_providerlink_api(user, user_params["role_id"], "update")
        end
      end

      # redirect(conn, to: main_user_path(conn, :show, user))
      changeset = user |> User.changeset2(user_params)
      conn
      |> put_flash(:info, "Update Successful")
      |> redirect(to: "/web/users/#{user.id}")
    else
      {:error, changeset} ->
        render(
          conn,
          "edit.html",
          changeset: changeset,
          roles: roles,
          user: user,
          companies: companies
        )
    end
  end

  def show(conn, %{"id" => user_id}) do
    pem_role = conn.private.guardian_default_claims["pem"]["roles"]
    user = get_user!(user_id)

    if is_nil(user) do
      conn
      |> put_flash(:error, "Invalid User!")
      |> redirect(to: user_path(conn, :index))
    else
      render(conn, "show.html", user: user, permission: pem_role)
    end
  end

  def check_existing_username(conn, params) do
    with true <- Map.has_key?(params, "username")
    do
      if is_nil(UserContext.check_user_by_username(params["username"])) do
        json(conn, %{valid: true})
      else
        json(conn, %{valid: false})
      end
    else
      _ ->
        json(conn, %{valid: false})
    end
  end

  def check_existing_mobile(conn, %{"mobile" => mobile, "current_mobile" => current_mobile}) do
    mobile = String.replace(mobile, "-", "")
    if is_nil(UserContext.check_user_by_mobile(mobile, current_mobile)) do
      json(conn, %{valid: true})
    else
      json(conn, %{valid: false})
    end
  end

  def check_existing_mobile(conn, params) do
    with true <- Map.has_key?(params, "mobile") do
      mobile = String.replace(params["mobile"], "-", "")
      if is_nil(UserContext.check_user_by_mobile(mobile)) do
        json(conn, %{valid: true})
      else
        json(conn, %{valid: false})
      end
    else
      _ ->
        json(conn, %{valid: false})
    end
  end

  def check_existing_email(conn, %{"email" => email, "current_email" => current_email}) do
    if is_nil(UserContext.check_user_by_email(email, current_email)) do
      json(conn, %{valid: true})
    else
      json(conn, %{valid: false})
    end
  end

  def check_existing_email(conn, %{"email" => email}) do
    if is_nil(UserContext.check_user_by_email(email)) do
      json(conn, %{valid: true})
    else
      json(conn, %{valid: false})
    end
  end

  def check_existing_email(conn, _params), do: json(conn, %{valid: false})

  def check_existing_payroll(conn, %{"payroll_code" => payroll_code, "current_payroll_code" => current_payroll_code, "company_id" => company_id}) do
    if is_nil(UserContext.check_user_by_payroll(payroll_code, current_payroll_code, company_id)) do
      json(conn, %{valid: true})
    else
      json(conn, %{valid: false})
    end
  end

  def check_existing_payroll(conn, %{"payroll_code" => payroll_code, "company_id" => company_id}) do
    if is_nil(UserContext.check_user_by_payroll(payroll_code, company_id)) do
      json(conn, %{valid: true})
    else
      json(conn, %{valid: false})
    end
  end

  def check_existing_payroll(conn, _params), do: json(conn, %{valid: false})

  def get_all_company_users(conn, %{"company_id" => ""}) do
    json(conn, [])
  end

  def get_all_company_users(conn, %{"company_id" => company_id}) do
    users = UserContext.get_users_by_company(company_id)
    json(conn, users)
  end

  def get_all_company_users(conn, %{}) do
    json(conn, [])
  end

  def update_user_status(conn, %{"id" => user_id, "user" => user_params}) do
    with %User{} = user <- UserContext.get_user!(user_id),
         true <- Map.has_key?(user_params, "action"),
         true <- Enum.member?(["Active", "Deactivated"], user_params["action"])
    do
      user_with_status = UserContext.update_user_status(user, user_params["action"])

      user_roles =
        user.roles
        |> List.first()

      role_application =
        user_roles.role_applications
        |> List.first()

      application = role_application.application.name

      if application == "ProviderLink" do
        UserContext.match_user_providerlink_api(user, user_params["role_id"], "update")
      end
      json(conn, %{valid: true})
    else
      _ ->
        json(conn, %{valid: false})
    end
  end

  def index_data(conn, params) do
    count = UDT.count(params["search"]["value"])
    accounts = UDT.get_users(params["start"], params["length"], params["search"]["value"], params["id"])
    conn |> json(%{data: accounts, draw: params["draw"], recordsTotal: count, recordsFiltered: count})
  end

end
