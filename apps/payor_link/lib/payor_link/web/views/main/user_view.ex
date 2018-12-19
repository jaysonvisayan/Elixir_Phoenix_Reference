defmodule Innerpeace.PayorLink.Web.Main.UserView do
  use Innerpeace.PayorLink.Web, :view

  def display_role_applications(role_applications) do
  	application_names =
  		Enum.map(role_applications, fn(role_application) ->
  			role_application.application.name
  		end)
  	application_names |> Enum.join(", ")
  end

  def display_updated_by(user) do
  	if is_nil(user) do
  		"n/a"
  	else
  		user.username
  	end
  end

  def display_roles(roles) do
    Enum.map(roles, fn(role) ->
      role.name
    end)
  end

  def display_name(user) do
    "#{user.first_name} #{user.last_name}"
  end

  def map_companies(companies) do
    companies
    |> Enum.map(&(({&1.name, &1.id})))
  end

  def display_user_company(user) do
    if is_nil(user.company) do
      ""
    else
      user.company.name
    end
  end

  def notification_checker(user) do
   applications =
      user.roles
      |> Enum.map(fn(ur) ->
          if Enum.empty?(ur.role_applications) do
            []
          else
            Enum.map(ur.role_applications, fn(ra) ->
              ra.application.name
            end)
          end
        end)
      |> Enum.uniq()
      |> List.flatten()

    permissions =
      user.roles
      |> Enum.map(fn(ur) ->
          if Enum.empty?(ur.role_permissions) do
            []
          else
            Enum.map(ur.role_permissions, fn(rp) ->
              rp.permission.name
            end)
          end
         end)
      |> Enum.uniq()
      |> List.flatten()

    with true <- Enum.all?([
      Enum.member?(applications, "ProviderLink"),
      Enum.member?(permissions, "Manage ProviderLink ACU Schedules"),
      user.acu_schedule_notification
    ])
    do
      true
    else
      false ->
        false
      _ ->
        false
    end
  end

  def display_user_facility(nil), do: ""
  def display_user_facility(facility), do: facility.name

  def get_user_application([]), do: ""
  def get_user_application(user_roles) do
    user_role = List.first(user_roles)
    user_role.role_applications
    |> display_role_applications()
  end

end
