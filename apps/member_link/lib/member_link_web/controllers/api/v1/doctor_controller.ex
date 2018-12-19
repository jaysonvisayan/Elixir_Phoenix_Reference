defmodule MemberLinkWeb.Api.V1.DoctorController do
  use MemberLinkWeb, :controller

  alias Guardian.Plug
  alias Innerpeace.Db.Base.{
    PractitionerContext,
    SpecializationContext
  }
  # alias Innerpeace.Db.Schemas.{
  #   Specialization
  # }

  alias Innerpeace.Db.Base.Api.UtilityContext
  alias MemberLink.Guardian, as: MG

  def search(conn, params) do
    user = MG.current_resource_api(conn)
    if params == %{} ||
      Enum.all?([params["name"] == "", params["hospital"] == "", params["specialization"] == "", params["gender"] == "", params["availability"] == ""])
    do
      practitioners = PractitionerContext.search_all_practitioners_api(user.member_id)
      practitioners_checker(conn, practitioners)
    else
      if is_nil(params["availability"]) || params["availability"] == "" do
        practitioners = PractitionerContext.search_practitioner_api(params, user.member_id)
        practitioner_checker_with_params(conn, practitioners, params)
      else
        schedule_param = UtilityContext.transform_date_search(params["availability"])
        if schedule_param == {:invalid_datetime_format} do
          error_msg(conn, 400, "Invalid Date Format")
        else
          params = Map.put(params, "availability", schedule_param)
          practitioners = PractitionerContext.search_practitioner_api(params, user.member_id)
          practitioner_checker_with_params(conn, practitioners, params)
        end
      end
    end
  end

  defp practitioners_checker(conn, practitioners) do
    if Enum.empty?(practitioners) do
      error_msg(conn, 404, "No Doctors Found")
    else
      render(conn, "show.json", practitioners: practitioners)
    end
  end

  defp practitioner_checker_with_params(conn, practitioners, params) do
    if Enum.empty?(practitioners) do
      error_msg(conn, 404, "No Doctors Found")
    else
      render(conn, "show.json", practitioners: practitioners)
    end
  end

  def get_specializations(conn, _params) do
    specializations = SpecializationContext.get_all_specializations()
    if specializations == [] do
      error_msg(conn, 404, "No Specializations Found")
    else
      render(conn, "show_specializations.json", specializations: specializations)
    end
  end

  defp error_msg(conn, status, message) do
    conn
    |> put_status(status)
    |> render(MemberLinkWeb.Api.ErrorView, "error.json", message: message, code: status)
  end
end
