defmodule MemberLinkWeb.Api.V1.DoctorView do
  use MemberLinkWeb, :view

  def render("show.json", %{practitioners: practitioners}) do
    practitioners = for ps <- practitioners do
      fpf =
        ps.practitioner.practitioner_facilities
        |> Enum.map(& (if &1.practitioner_status.value == "Affiliated" && &1.step > 5 && (&1.facility.type.value == "HB" || &1.facility.type.value == "CB"), do: &1))
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.flatten()
        for pf <- fpf do
          %{
            id: pf.practitioner.id,
            code: pf.practitioner.code,
            name: pf.practitioner.first_name <> " " <> pf.practitioner.last_name,
            specialization: render_one(ps, MemberLinkWeb.Api.V1.DoctorView, "practitioner_specializations.json", as: :practitioner_specializations),
            facility: render_one(pf, MemberLinkWeb.Api.V1.DoctorView, "practitioner_facilities.json", as: :practitioner_facilities),
            gender: pf.practitioner.gender,
            status: pf.practitioner.status,
            contact:
            if ps.practitioner.practitioner_contact == nil do
              []
            else
              render_many(ps.practitioner.practitioner_contact.contact.phones, MemberLinkWeb.Api.V1.DoctorView, "practitioner_contact.json", as: :practitioner_contact)
            end
          }
        end
    end
    practitioners
    |> List.flatten()
  end

  def render("show_search.json", %{practitioners: practitioner}) do
    %{
    practitioner: Enum.concat(render_many(practitioner, MemberLinkWeb.Api.V1.DoctorView, "practitioner_search.json", as: :practitioner))
    }
  end

  def render("show_facility.json", %{practitioners: practitioner}) do
    %{
    practitioner: render_many(practitioner, MemberLinkWeb.Api.V1.DoctorView, "facility.json", as: :facility)
    }
  end

  def render("show_practitioner_facility.json", %{practitioners: practitioner_facilities}) do
    %{
      practitioner:
      for p <- practitioner_facilities do
        %{
          id: p.practitioner.id,
          code: p.practitioner.code,
          name: p.practitioner.first_name <> " " <> p.practitioner.last_name,
          specialization: render_one(p.practitioner.practitioner_specializations, MemberLinkWeb.Api.V1.DoctorView, "practitioner_specializations.json", as: :practitioner_specializations),
          sub_specialization: Enum.filter(render_many(p.practitioner.practitioner_specializations, MemberLinkWeb.Api.V1.DoctorView, "practitioner_sub_specializations.json", as: :practitioner_sub_specializations), & !is_nil(&1)),
          facility: render_one(p, MemberLinkWeb.Api.V1.DoctorView, "practitioner_facilities.json", as: :practitioner_facilities),
          contact:
          if p.practitioner.practitioner_contact == nil do
            []
          else
          render_many(p.practitioner.practitioner_contact.contact.phones, MemberLinkWeb.Api.V1.DoctorView, "practitioner_contact.json", as: :practitioner_contact)
          end
        }
      end
    }
  end

  def render("practitioner_search.json", %{practitioner: practitioner}) do
    for pf <- practitioner.practitioner_facilities do
      %{
        id: practitioner.id,
        code: practitioner.code,
        name: practitioner.first_name <> " " <> practitioner.last_name,
        specialization: render_one(practitioner.practitioner_specializations, MemberLinkWeb.Api.V1.DoctorView, "practitioner_specializations.json", as: :practitioner_specializations),
        sub_specialization: Enum.filter(render_many(practitioner.practitioner_specializations, MemberLinkWeb.Api.V1.DoctorView, "practitioner_sub_specializations.json", as: :practitioner_sub_specializations), & !is_nil(&1)),
        facility: render_one(pf, MemberLinkWeb.Api.V1.DoctorView, "practitioner_facilities.json", as: :practitioner_facilities),
        gender: practitioner.gender,
        contact:
        if practitioner.practitioner_contact == nil do
          []
        else
        render_many(practitioner.practitioner_contact.contact.phones, MemberLinkWeb.Api.V1.DoctorView, "practitioner_contact.json", as: :practitioner_contact)
        end
      }
    end
  end


  def render("practitioner.json", %{practitioner: pf}) do
      %{
        id: pf.practitioner.id,
        code: pf.practitioner.code,
        name: pf.practitioner.first_name <> " " <> pf.practitioner.last_name,
        specialization: render_many(pf.practitioner.practitioner_specializations, MemberLinkWeb.Api.V1.DoctorView, "practitioner_specializations.json", as: :practitioner_specializations),
        #sub_specialization: Enum.filter(render_many(pf.practitioner.practitioner_specializations, MemberLinkWeb.Api.V1.DoctorView, "practitioner_sub_specializations.json", as: :practitioner_sub_specializations), & !is_nil(&1)),
        facility: render_one(pf, MemberLinkWeb.Api.V1.DoctorView, "practitioner_facilities.json", as: :practitioner_facilities),
        gender: pf.practitioner.gender,
        status: pf.practitioner.status,
        contact:
        if pf.practitioner.practitioner_contact == nil do
          []
        else
        render_many(pf.practitioner.practitioner_contact.contact.phones, MemberLinkWeb.Api.V1.DoctorView, "practitioner_contact.json", as: :practitioner_contact)
        end
      }
  end

  def render("facility.json", %{facility: facility}) do
    for pf <- facility.practitioner_facilities do
      %{
        id: pf.practitioner.id,
        code: pf.practitioner.code,
        name: Enum.join([pf.practitioner.first_name, pf.practitioner.last_name], " "),
        specialization: render_one(pf.practitioner.practitioner_specializations, MemberLinkWeb.Api.V1.DoctorView, "practitioner_specializations.json", as: :practitioner_specializations),
        sub_specialization: Enum.filter(render_many(pf.practitioner.practitioner_specializations, MemberLinkWeb.Api.V1.DoctorView, "practitioner_sub_specializations.json", as: :practitioner_sub_specializations), & !is_nil(&1)),
        facility: render_one(pf, MemberLinkWeb.Api.V1.DoctorView, "practitioner_facilities.json", as: :practitioner_facilities),
        contact: render_many(pf.practitioner.practitioner_contact.contact.phones, MemberLinkWeb.Api.V1.DoctorView, "practitioner_contact.json", as: :practitioner_contact),
        gender: pf.practitioner.gender
      }
    end
  end

  def render("practitioner_contact.json", %{practitioner_contact: phone}) do
    %{
      type: phone.type,
      number: phone.number
    }
  end

  def render("practitioner_facilities.json", %{practitioner_facilities: practitioner_facilities}) do
    %{
      id: practitioner_facilities.facility.id,
      code: practitioner_facilities.facility.code,
      name: practitioner_facilities.facility.name,
      long: practitioner_facilities.facility.longitude,
      lat: practitioner_facilities.facility.latitude,
      address: Enum.join([practitioner_facilities.facility.line_1,
                          practitioner_facilities.facility.line_2,
                          practitioner_facilities.facility.city,
                          practitioner_facilities.facility.province,
                          practitioner_facilities.facility.region,
                          practitioner_facilities.facility.country,
                          practitioner_facilities.facility.postal_code], " "),
      schedule: render_many(practitioner_facilities.practitioner_schedules, MemberLinkWeb.Api.V1.DoctorView, "practitioner_schedules.json", as: :practitioner_schedules),
     affiliated: if practitioner_facilities.practitioner_status.value == "Affiliated" do true else false end
    }
  end

  def render("practitioner_schedules.json", %{practitioner_schedules: practitioner_schedule}) do
    %{
      day: practitioner_schedule.day,
      room: practitioner_schedule.room,
      time_from: practitioner_schedule.time_from,
      time_to: practitioner_schedule.time_to
    }
  end

  def render("practitioner_specializations.json", %{practitioner_specializations: practitioner_specializations}) do
    # specializations = for pf <- practitioner_specializations do
    #   if pf.type  == "Primary" do
    #     pf.specialization
    #   end
    # end
    # specializations = Enum.filter(specializations, & !is_nil(&1))
    # if specializations == [] do
    # %{
    # }
    # else
    # %{
    #   name: Enum.at(specializations, 0).name
    # }
    # end

      %{
        practitioner_specialization_id: practitioner_specializations.id,
        id: practitioner_specializations.specialization.id,
        name: practitioner_specializations.specialization.name,
        type: practitioner_specializations.type
      }
  end
  def render("practitioner_sub_specializations.json", %{practitioner_sub_specializations: practitioner_specializations}) do
      if practitioner_specializations.type  == "Secondary" do
    %{
      name: practitioner_specializations.specialization.name
    }
      end
  end

  def render("show_specializations.json", %{specializations: specializations}) do
    %{
      specializations: render_many(specializations, MemberLinkWeb.Api.V1.DoctorView, "specializations.json", as: :specializations)
    }
  end

  def render("specializations.json", %{specializations: specializations}) do
    %{
      id: specializations.id,
      name: specializations.name
    }
  end
end
