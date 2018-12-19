defmodule Innerpeace.PayorLink.Web.Main.RoleView do
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

  def display_updated_by(role) do
  	if is_nil(role) do
  		"n/a"
  	else
  		role.username
  	end
  end

  def display_role_applications(role_applications) do
  	application_names =
  		Enum.map(role_applications, fn(role_application) ->
  			role_application.application.name
  		end)
  	application_names |> Enum.join(", ")
  end

  def get_permission_by_module(module_name, role_id) do
    role = RoleContext.get_role(role_id)
    keyword = Enum.map(role.role_permissions, fn(rp) ->
      if Enum.any?([is_nil(rp), is_nil(rp.permission)])do
        nil
      else
        PermissionContext.get_permission_access_by_module(module_name, rp.permission.name)
      end
    end)

    keyword =
      keyword
      |> Enum.reject(&(&1 == nil))
      |> List.first()

    cond do
      is_nil(keyword) ->
        "Not Allowed"
      keyword =~ "manage" ->
        "Full Access"
      keyword =~ "access" ->
        "Read Only"
      true ->
        "Not Allowed"
    end
  end

  def create_user_for(role) do
    String.capitalize(role.create_full_access)
  end

  def get_pii(role) do
    if role.pii do
      "Yes"
    else
      "No"
    end
  end

  def get_cut_off_dates(cut_off_dates) do
    if is_nil(cut_off_dates) do
      "N/A"
    else
      if Enum.empty?(cut_off_dates) do
        "N/A"
      else
        dates = Enum.map(cut_off_dates, fn(x) ->
          case x do
            1 ->
              Enum.join([x, "st"], "")
            2 ->
              Enum.join([x, "nd"], "")
            3 ->
              Enum.join([x, "rd"], "")
            _ ->
              Enum.join([x, "th"], "")
          end
        end)
        if Enum.count(dates) > 1 do
          Enum.join(dates, ", ") <> " of the month "
        else
          date =
            dates
            |> List.first()
            date <> " of the month"
        end
      end
    end
  end

  def check_cut_off_dates(nil), do: false
  def check_cut_off_dates([]), do: false
  def check_cut_off_dates(cut_off_dates), do: true

end
