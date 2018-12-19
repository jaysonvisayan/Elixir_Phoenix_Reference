defmodule MemberLinkWeb.Api.V1.HospitalController do
  use MemberLinkWeb, :controller

  alias MemberLink.Guardian.Plug
  alias Innerpeace.Db.{
    Base.Api.FacilityContext,
    # Schemas.Facility
  }
  alias MemberLink.Guardian, as: MG

  def search(conn, params) do
    user = MG.current_resource_api(conn)

    if params == %{} ||
      Enum.all?([(params["name"] == "" || is_nil(params["name"])),
      (params["address"] == "" || is_nil(params["address"])),
      (params["city"] == "" || is_nil(params["city"])),
      (params["region"] == "" || is_nil(params["region"]))]
      )
    do
      facilities = FacilityContext.search_all_facility_member_api(user.member_id)
      if facilities == [] do
        error_msg(conn, 404, "No Hospitals Found")
      else
        render(conn, "show.json", facilities: facilities)
      end
    else
      facilities =
        params
        |> FacilityContext.search_facility_memberlink_api(user.member_id)
      if facilities == [] do
        error_msg(conn, 404, "No Hospitals Found")
      else
        render(conn, "show.json", facilities: facilities)
      end
    end
  end

  defp error_msg(conn, status, message) do
    conn
    |> put_status(status)
    |> render(MemberLinkWeb.Api.ErrorView, "error.json", message: message, code: status)
  end
end
