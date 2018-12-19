defmodule Innerpeace.PayorLink.Web.Api.V1.FacilityView do
  use Innerpeace.PayorLink.Web, :view

  def render("facility_payor_procedure.json", %{facility_payor_procedure: facility_payor_procedure}) do
    %{
    code: facility_payor_procedure.code,
    name: facility_payor_procedure.name,
    id: facility_payor_procedure.id,
    facility_payor_procedure_rooms: render_many(
      facility_payor_procedure.facility_payor_procedure_rooms,
      Innerpeace.PayorLink.Web.Api.V1.FacilityView,
      "facility_payor_procedure_rooms.json", as: :facility_payor_procedure_rooms),
    facility: render_one(
      facility_payor_procedure.facility,
      Innerpeace.PayorLink.Web.Api.V1.FacilityView,
      "facility.json", as: :facility)
    }
  end

  def render("show.json", %{facility: facility}) do
    %{facility: render_one(
        facility, Innerpeace.PayorLink.Web.Api.V1.FacilityView,
        "facility2.json", as: :facility)}
  end

  def render("facility2.json", %{facility: facility}) do
    %{
      id: facility.id,
      region: facility.region,
      code: facility.code,
      name: facility.name,
      latitude: facility.latitude,
      longitude: facility.longitude,
      phone_no: facility.phone_no,
      line_1: facility.line_1,
      line_2: facility.line_2,
      city: facility.city,
      province: facility.province,
      country: facility.country,
      postal_code: facility.postal_code
    }
  end

  def render("facility_payor_procedure_rooms.json", %{facility_payor_procedure_rooms: facility_payor_procedure_rooms}) do
    %{
      amount: facility_payor_procedure_rooms.amount,
      discount: facility_payor_procedure_rooms.discount,
      start_date: facility_payor_procedure_rooms.start_date,
      id: facility_payor_procedure_rooms.id,
      facility_room_rate: render_one(
        facility_payor_procedure_rooms.facility_room_rate,
        Innerpeace.PayorLink.Web.Api.V1.FacilityView,
        "facility_room_rate.json", as: :facility_room_rate),
    }
  end

  def render("facility_room_rate.json", %{facility_room_rate: facility_room_rate}) do
    %{
      id: facility_room_rate.id,
      facility_room_type: facility_room_rate.facility_room_type,
      facility_room_rate: facility_room_rate.facility_room_rate,
      rooms: render_one(facility_room_rate.room,
        Innerpeace.PayorLink.Web.Api.V1.FacilityView,
        "room.json", as: :room),
    }
  end

  def render("room.json", %{room: room}) do
    %{
      id: room.id,
      code: room.code,
      type: room.type,
      hierarchy: room.hierarchy
    }
  end

  def render("vendor_code.json", %{code: code}) do
    %{code: code}
  end

  def render("index.json", %{facility: facility}) do
    %{data: render_many(facility,
      Innerpeace.PayorLink.Web.Api.V1.FacilityView,
      "facility.json", as: :facility)}
  end

  def render("facility.json", %{facility: facility}) do
    %{
      id: facility.id,
      region: facility.region,
      code: facility.code,
      name: facility.name,
      latitude: facility.latitude,
      longitude: facility.longitude,
      phone_no: facility.phone_no,
      line_1: facility.line_1,
      line_2: facility.line_2,
      city: facility.city,
      province: facility.province,
      country: facility.country,
      postal_code: facility.postal_code,
      email_address: facility.email_address,
      prescription_term: facility.prescription_term,
      affiliated_practitioner: render_many(facility.practitioner_facilities, 
      Innerpeace.PayorLink.Web.Api.V1.FacilityView,
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

  def render("facility_web.json", %{facilities: facilities}) do
    %{data:
      render_many(facilities, Innerpeace.PayorLink.Web.Api.V1.FacilityView,
        "facilities_web.json", as: :facilities),
      count: Enum.count(facilities)}
  end

  def render("facilities_web.json", %{facilities: facilities}) do
      %{
        text: facilities.name,
        value: facilities.id
      }
  end

  def render("facility_contacts.json", %{facility_contacts: facility_contacts}) do
    %{
      type: facility_contacts.type,
      first_name: facility_contacts.first_name,
      last_name: facility_contacts.last_name,
      suffix: facility_contacts.suffix,
      department: facility_contacts.department,
      designation: facility_contacts.designation,
      emails: facility_contacts.emails,
      ctc_number: facility_contacts.ctc,
      ctc_date_issued: facility_contacts.ctc_date_issued,
      ctc_place_issued: facility_contacts.ctc_place_issued,
      passport_number: facility_contacts.passport_no,
      passport_date_issued: facility_contacts.passport_date_issued,
      phones: render_many(
        facility_contacts.phones, Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "contact_phones.json", as: :phone)
    }
  end
end
