defmodule MemberLinkWeb.Api.V1.HospitalView do
  use MemberLinkWeb, :view

  def render("show.json", %{facilities: facilities}) do
    %{
      hospitals: render_many(facilities, MemberLinkWeb.Api.V1.HospitalView, "facility.json", as: :facility)
    }
  end

  def render("facility.json", %{facility: facility}) do
    %{
      id: facility.id,
      code: facility.code,
      name: facility.name,
      long: facility.longitude,
      lat: facility.latitude,
      affiliated: if facility.status == "Affiliated" do true else false end,
      address: Enum.join([
      facility.line_1,
      facility.line_2,
      facility.city,
      facility.province,
      facility.region,
      facility.country,
      facility.postal_code
      ], " ")
    }
  end

end
