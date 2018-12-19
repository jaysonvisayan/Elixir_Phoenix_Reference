defmodule Innerpeace.PayorLink.Web.Api.V1.Vendor.PractitionerView do
  use Innerpeace.PayorLink.Web, :view

  def render("accredited_verification.json", %{status: status}) do
    %{
      status: status
    }
  end

  def render("affiliated_verification.json", %{status: status}) do
    %{
      status: status
    }
  end

  def render("practitioners.json", %{practitioners: practitioners}) do
    %{data: render_many(practitioners,
                        Innerpeace.PayorLink.Web.Api.V1.Vendor.PractitionerView,
                        "practitioner.json", as: :practitioner)}
  end

  def render("practitioner.json", %{practitioner: practitioner}) do
    primary_specialization =
      practitioner.practitioner_specializations
      |> Enum.filter(&(&1.type == "Primary"))
      |> Enum.map(&(&1.specialization.name))
      |> List.first

    sub_specialization =
      practitioner.practitioner_specializations
      |> Enum.filter(&(&1.type == "Secondary"))
      |> Enum.map(&(&1.specialization.name))
      |> Enum.join(", ")

    %{
      practitioner_code: practitioner.code,
      name: "#{practitioner.first_name} #{practitioner.middle_name} #{practitioner.last_name}",
      gender: practitioner.gender,
      status: practitioner.status,
      specialization: %{
        specialization: primary_specialization,
        sub_specialization: sub_specialization
      },
      facilities: render_many(practitioner.practitioner_facilities,
                        Innerpeace.PayorLink.Web.Api.V1.Vendor.PractitionerView,
                        "practitioner_facility.json", as: :practitioner_facility)
    }
  end

  def render("practitioner_facility.json", %{practitioner_facility: practitioner_facility}) do
    %{
      code: practitioner_facility.facility.code,
      name: practitioner_facility.facility.name
    }
  end
end
