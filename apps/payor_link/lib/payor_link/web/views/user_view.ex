defmodule Innerpeace.PayorLink.Web.UserView do
  use Innerpeace.PayorLink.Web, :view

  def map_applications(applications) do
    applications
    |> Enum.map(&(&1.name))
    |> Enum.sort()
  end

  def user_roles_list_ids(user) do
    [] ++ for role <- user.roles do
      role.id
    end
  end

  def user_roles_list_names(user) do
    user
    |> Enum.map(&(&1.name))
    |> Enum.join(", ")
  end

  def display_user_roles(user) do
    roles = [] ++ for role <- user.roles, do: role.name
    Enum.join(roles, ", ")
  end

  def filter_nil(var) do
    raise var
  end

  def check_active_step(conn, step) do
    step = Integer.to_string(step)
    current_step = conn.params["step"]
    if step == current_step do
      "active"
    else
      if String.to_integer(step) < String.to_integer(current_step) do
        "completed"
      else
        "disabled"
      end
    end
  end

end
