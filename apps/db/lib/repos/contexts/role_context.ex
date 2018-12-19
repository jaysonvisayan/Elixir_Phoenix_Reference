defmodule Innerpeace.Db.Base.RoleContext do
  alias Innerpeace.Db.{
    Repo,
    Schemas.Role,
    Schemas.RolePermission,
    Schemas.Permission,
    Schemas.Application,
    Schemas.RoleApplication,
    Schemas.CoverageApprovalLimitAmount,
    Base.CoverageContext,
    Base.PermissionContext,
    Base.ApiAddressContext,
    Base.ApplicationContext
  }
  import Ecto.Query

  def insert_or_update_role(params) do
    role = get_role_by_name(params.name)
    if is_nil(role) do
      create_role(params)
    else
      update_role(role.id, params)
    end
  end

  def get_role_by_name(name) do
    Role
    |> Repo.get_by(name: name)
  end

  def insert_or_update_role_application(params) do
    role_application =
      RoleApplication
      |> Repo.get_by(role_id: params.role_id, application_id: params.application_id)
    if is_nil(role_application) do
      create_role_application(params.role_id, [params.application_id])
    end
  end

  def insert_or_update_role_permission(params) do
    role_permission = get_role_permission_by_role_id(params.role_id, params.permission_id)
    if is_nil(role_permission) do
      create_role_permission(params.role_id, params.permission_id)
    end
  end

  def clear_role_permission_using_role_id(role_id, permission_id) do
    RolePermission
    |> where([rp], rp.role_id == ^role_id and rp.permission_id == ^permission_id)
    |> Repo.delete_all()
  end

  def clear_coverage_approval_limit_amount(role_id) do
    CoverageApprovalLimitAmount
    |> where([cal], cal.role_id == ^role_id)
    |> Repo.delete_all()
  end

  def get_role_application_by_role_id(role_id) do
    RoleApplication
    |> Repo.get_by(role_id: role_id)
  end

  def get_role_permission_by_role_id(role_id, permission_id) do
    RolePermission
    |> Repo.get_by(role_id: role_id, permission_id: permission_id)
  end

  def get_all_roles do
    Role
    |> order_by(asc: :updated_at)
    |> Repo.all
    |> Repo.preload([
      [role_applications: :application],
      :created_by, :updated_by,
      [role_permissions: :permission],
      [coverage_approval_limit_amounts: :coverage]
    ])
  end

  def get_role(id) do
    Role
    |> Repo.get!(id)
    |> Repo.preload([
      :users,
      :created_by, :updated_by,
      [role_applications: :application],
      [role_permissions: :permission],
      [coverage_approval_limit_amounts: :coverage]])
  end

  def get_role_permission(id) do
    RolePermission
    |> Repo.get_by!(role_id: id)
    |> Repo.preload([:permission, :role])
  end

  def create_role(role_param) do
    %Role{}
    |> Role.changeset(role_param)
    |> Repo.insert
  end

  def create_role_permission(role_id, permission_id) do
    %RolePermission{}
    |> RolePermission.changeset(%{role_id: role_id, permission_id: permission_id})
    |> Repo.insert!()
  end

  def create_role_permissions(role_id, permission_ids) do
    for permission_id <- permission_ids do
      if permission_id != "" do
        %RolePermission{}
        |> RolePermission.changeset(%{role_id: role_id, permission_id: permission_id})
        |> Repo.insert!()
      end
    end
  end

  def create_virtual_role_permission(params) do
    %RolePermission{}
    |> RolePermission.virtual_changeset(params)
    |> Repo.insert
  end

  def update_role(id, role_param) do
    id
    |> get_role()
    |> Role.changeset(role_param)
    |> Repo.update
  end

  def delete_role(id) do
    id
    |> get_role()
    |> Repo.delete
  end

  def check_role_permission(role_id) do
    RolePermission
    |> where([rp], rp.role_id == ^role_id)
    |> select([rp], rp.permission_id)
    |> Repo.all
  end

  def add_created_by(role, user) do
    if role.status == "submitted" do
      role_params = %{"updated_by_id" => user}
    else
      role_params = %{
        "status" => "submitted",
        "created_by_id" => user
      }
    end
  end

  def change_role(%Role{} = role) do
    Role.changeset(role, %{})
  end

  def change_role_permission(%RolePermission{} = role_permission) do
    RolePermission.changeset(role_permission, %{})
  end

  def payor_modules(param) do
    RolePermission
    |> where([rp], rp.role_id == ^param["role_permission"])
    |> Repo.delete_all
    query = Innerpeace.Db.Base.PermissionContext.load_all_permission()
    modules = Enum.map(query, fn(p) ->
      p.module
      module = [p.module, "_permissions"] |> Enum.join() |> String.downcase
      param[module]
    end)

    modules
    |> Enum.reject(&(is_nil(&1) or &1 == ""))
    |> Enum.map(fn(module) ->
      insert_role_permissions(module, param["role_permission"])
    end)
  end

  defp insert_role_permissions(module, role_id) do
    permission = PermissionContext.get_permission_by_keyword(module)
    %RolePermission{}
    |> RolePermission.changeset(%{
      role_id: role_id,
      permission_id: permission
    })
    |> Repo.insert
  end

  def clear_role_permission do
    RolePermission
    |> where([rp], is_nil(rp.role_id) or is_nil(rp.permission_id))
    |> Repo.delete_all()
  end

  def load_role_permissions(role_id, permission_id) do
    role = Repo.get_by(RolePermission, role_id: role_id, permission_id: permission_id)
    if role != nil do
      permission  = Repo.get_by(Permission,  id: role.permission_id)
      case permission.name =~ "Manage" do
        true ->
          role = "manage"
        false ->
          role = "access"
      end
      else
      role = "null"
    end
  end

  def create_role_application(role_id, application_ids) do
    RoleApplication
    |> where([ra], ra.role_id == ^role_id)
    |> Repo.delete_all
    for application_id <- application_ids do
      if application_id != "" do
        %RoleApplication{}
        |> RoleApplication.changeset(%{role_id: role_id, application_id: application_id})
        |> Repo.insert
      end
    end
    {:ok}
  end

  def select_all_role_names do
    Role
    |> select([:name])
    |> Repo.all
  end

  def create_role_new(role_param) do
    %Role{}
    |> Role.changeset_role(role_param)
    |> Repo.insert()
  end

  def update_role_new(role, role_param) do
    role
    |> Role.changeset_role(role_param)
    |> Repo.update()
  end

  def create_coverage_limit(role_id, approval_limit) do
    approval_limits =
      approval_limit
      |>  Enum.filter(fn({_coverage, val}) -> val != "" end)
      |>  Enum.map(fn({coverage, val}) -> {coverage, val} end)

    for {coverage, val} <- approval_limits do
      coverage = CoverageContext.get_coverage_by_id(coverage)
      coverage_limit_amount = get_coverage_limit_amount(role_id, coverage.id)
      if not is_nil(coverage_limit_amount) do
        Repo.delete(coverage_limit_amount)
        limit_amount =
          %CoverageApprovalLimitAmount{}
          |> CoverageApprovalLimitAmount.changeset(%{
            role_id: role_id,
            coverage_id: coverage.id,
            approval_limit_amount: val
          })
          |> Repo.insert()
      else
        limit_amount =
          %CoverageApprovalLimitAmount{}
          |> CoverageApprovalLimitAmount.changeset(%{
            role_id: role_id,
            coverage_id: coverage.id,
            approval_limit_amount: val
          })
          |> Repo.insert()
      end
    end
    {:ok}
  end

  def get_coverage_limit_amount(role_id, coverage_id) do
    CoverageApprovalLimitAmount
    |> where([cl], cl.role_id == ^role_id and cl.coverage_id == ^coverage_id)
    |> Repo.one()
  end

  def providerlink_sign_in_v2() do
    api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
    providerlink_sign_in_url = "#{api_address.address}/api/v1/sign_in"
    headers = [{"Content-type", "application/json"}]
    body = Poison.encode!(%{"username": api_address.username, "password": api_address.password})

    with {:ok, response} <- HTTPoison.post(providerlink_sign_in_url, body, headers, []),
         200 <- response.status_code
    do
      decoded =
        response.body
        |> Poison.decode!()

      {:ok, decoded["token"]}
    else
      {:error, response} ->
        {:unable_to_login, response}
      _ ->
        {:unable_to_login, "Error occurs when attempting to login in Providerlink"}
    end
  end

  def create_role_providerlink_api(role_id) do
    role = get_role(role_id)
    permissions = Enum.map(role.role_permissions, fn(rp) ->
      %{
        payorlink_permission_id: rp.permission.id,
        name: rp.permission.name,
        module: rp.permission.module,
        status: rp.permission.status,
        description: rp.permission.description,
        keyword: rp.permission.keyword,
        payorlink_application_id: rp.permission.application_id
      }
    end)
    permissions = %{"permissions" => permissions}

    providerlink_application = ApplicationContext.get_application_by_name("ProviderLink")
    application = %{
      payorlink_application_id: providerlink_application.id,
      name: providerlink_application.name
    }

    role_params = %{
      payorlink_role_id: role.id,
      name: role.name,
      description: role.description,
      status: role.status,
      created_by_id: role.created_by_id,
      updated_by_id: role.updated_by_id,
      step: role.step,
      approval_limit: role.approval_limit,
      pii: role.pii,
      create_full_access: role.create_full_access,
      no_of_days: role.no_of_days,
      cut_off_dates: role.cut_off_dates,
      member_permitted: role.member_permitted,
      payorlink_application_id: providerlink_application.id,
      permissions: permissions
    }

    with {:ok, token} <- providerlink_sign_in_v2(),
         {:ok, response} <- create_application_providerlink(application, token),
         {:ok, response} <- create_permission_providerlink(permissions, token),
         {:ok, response} <- create_role_providerlink(role_params, token)
    do
      true
    else
      {:error, response} ->
        {:error, response}
      {:error_api_role} ->
        {:error, "Error creating providerlink role"}
      _ ->
        {:error, 500}
    end
  end

  def create_role_providerlink(params, token) do
    api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
    api_method = Enum.join([api_address.address, "/api/v1/roles/create_role_from_payorlink"], "")
    headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
    body = Poison.encode!(params)

    with {:ok, response} <- HTTPoison.post(api_method, body, headers, []),
         200 <- response.status_code
    do
      {:ok, response}
    else
      {:error, response} ->
        {:error, response}
      _ ->
        {:error_api_role}
    end
  end

  def update_role_providerlink_api(role_id) do
    role = get_role(role_id)
    permissions = Enum.map(role.role_permissions, fn(rp) ->
      %{
        payorlink_permission_id: rp.permission.id,
        name: rp.permission.name,
        module: rp.permission.module,
        status: rp.permission.status,
        description: rp.permission.description,
        keyword: rp.permission.keyword,
        payorlink_application_id: rp.permission.application_id
      }
    end)
    permissions = %{"permissions" => permissions}

    providerlink_application = ApplicationContext.get_application_by_name("ProviderLink")
    application = %{
      payorlink_application_id: providerlink_application.id,
      name: providerlink_application.name
    }

    role_params = %{
      payorlink_role_id: role.id,
      name: role.name,
      description: role.description,
      status: role.status,
      created_by_id: role.created_by_id,
      updated_by_id: role.updated_by_id,
      step: role.step,
      approval_limit: role.approval_limit,
      pii: role.pii,
      create_full_access: role.create_full_access,
      no_of_days: role.no_of_days,
      cut_off_dates: role.cut_off_dates,
      member_permitted: role.member_permitted,
      payorlink_application_id: providerlink_application.id,
      permissions: permissions
    }
    with {:ok, token} <- providerlink_sign_in_v2()
    do
      api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
      api_method = Enum.join([api_address.address, "/api/v1/roles/#{role_id}/update_role_from_payorlink"], "")
      headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
      body = Poison.encode!(role_params)

      with {:ok, response} <- HTTPoison.put(api_method, body, headers, []),
           200 <- response.status_code
      do
        {:ok, response}
      else
        {:error, response} ->
          {:error, response}
        _ ->
          {:error_api_role}
      end
    else
      {:error, response} ->
        {:error, response}
      {:error_api_role} ->
        {:error, "Error updating providerlink role"}
      _ ->
        {:error, 500}
    end
  end

  def create_permission_providerlink(params, token) do
    api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
    api_method = Enum.join([api_address.address, "/api/v1/permissions/create_permission_from_payorlink"], "")
    headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
    body = Poison.encode!(params)

    with {:ok, response} <- HTTPoison.post(api_method, body, headers, []),
         200 <- response.status_code
    do
      {:ok, response}
    else
      {:error, response} ->
        {:error, response}
      _ ->
        {:error_api_role}
    end
  end

  def create_application_providerlink(params, token) do
    api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
    api_method = Enum.join([api_address.address, "/api/v1/applications/create_application_from_payorlink"], "")
    headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
    body = Poison.encode!(params)

    with {:ok, response} <- HTTPoison.post(api_method, body, headers, []),
         200 <- response.status_code
    do
      {:ok, response}
    else
      {:error, response} ->
        {:error, response}
      _ ->
        {:error_api_role}
    end
  end

  def get_role_by_name_for_checker(name) do
    name = String.downcase(name)
    role = Role
          |> where([r], fragment("lower(?)", r.name) == ^name)
          |> Repo.one()
    if is_nil(role) do
      true
    else
      false
    end
  end
end
