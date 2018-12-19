defmodule Innerpeace.PayorLink.Web.Api.V1.Vendor.FacilityView do
  use Innerpeace.PayorLink.Web, :view

  def render("index.json", %{facility: facility}) do
    %{data: render_many(facility,
      Innerpeace.PayorLink.Web.Api.V1.Vendor.FacilityView,
      "facility.json", as: :facility)}
  end

  def render("facility.json", %{facility: facility}) do
    %{
      code: facility.code,
      name: facility.name,
      region: facility.region,
      province: facility.province,
      city: facility.city,
      postal: facility.postal_code,
      phone_number: facility.phone_no,
      latitude: facility.latitude,
      longitude: facility.longitude,
      affiliated_practitioner: render_many(facility.practitioner_facilities, 
      Innerpeace.PayorLink.Web.Api.V1.Vendor.FacilityView,
      "practitioner_facility.json", as: :practitioner_facility)
    }
  end

  def render("practitioner_facility.json", %{practitioner_facility: practitioner_facility}) do
    %{
      code: practitioner_facility.practitioner.code,
      name: Enum.join(["#{practitioner_facility.practitioner.first_name} ", 
            "#{practitioner_facility.practitioner.middle_name} ",
            "#{practitioner_facility.practitioner.last_name}"])
    } 
  end

  def render("facility_location.json", %{facility: facility}) do
    %{data: render_many(facility,
      Innerpeace.PayorLink.Web.Api.V1.Vendor.FacilityView,
      "facility_location_desc.json", as: :facility)}
  end

  def render("facility_location_desc.json", %{facility: facility}) do
    %{
      code: facility.code,
      name: facility.name,
      region: facility.region,
      province: facility.province,
      city: facility.city,
      address_line_1: facility.line_1,
      address_line_2: facility.line_2
    }
  end

end
