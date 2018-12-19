defmodule MemberLinkWeb.SearchView do
  use MemberLinkWeb, :view
  alias Innerpeace.Db.Base.{
    PractitionerContext,
    FacilityContext
  }
  alias Innerpeace.Db.Base.Api.FacilityContext, as: ApiFacilityContext

  def pf_checker(practitioner_id, member) do
    facilities = ApiFacilityContext.search_all_facility_member(member.id)
    practitioner = PractitionerContext.get_practitioner(practitioner_id)
    fpf = for f <- facilities do
      for pf <- f.practitioner_facilities do
        pf.id
      end
    end
    fpf = fpf |> List.flatten()
    ppf = for pf <- practitioner.practitioner_facilities do
      pf
    end
    Enum.filter(ppf, fn(x) -> Enum.member?(fpf, x.id) end)
  end

  def fpf_checker(facility_id) do
    facility = FacilityContext.get_facility!(facility_id)
    facility.practitioner_facilities
    |> Enum.map(& (if &1.practitioner_status.value == "Affiliated" && &1.step > 5, do: &1))
    |> Enum.uniq()
    |> List.delete(nil)
  end

  def get_contact_number(pfc) do
    if not is_nil(pfc) do
      phone_number = for phone <- pfc.contact.phones do
        phone.number
      end
      Enum.join(phone_number, ", ")
    end
  end

  def get_specialization(practitioner_specializations) do
    ps = Enum.filter(practitioner_specializations, &(&1.type == "Primary"))
    List.first(ps).specialization.name
  end

  def render("direction.json", %{facility: facility}) do
      %{
        id: facility.id,
        facility_code: facility.code,
        facility_name: facility.name,
        pf_count: Enum.count(facility.practitioner_facilities),
        facility_status: facility.status,
        facility_address1: Enum.join([facility.line_1, facility.line_2], " "),
        facility_address2: Enum.join([facility.city, "City", facility.postal_code, facility.province], " "),
        facility_phone_no: facility.phone_no,
        longitude: facility.longitude,
        latitude: facility.latitude,
        affiliated_doctors: Enum.count(facility.practitioner_facilities)
      }
  end

  def render("facilities.json", %{facilities: facilities}) do
    for facility <- facilities do
      fpf = facility.practitioner_facilities
            |> Enum.map(& (if &1.practitioner_status.value == "Affiliated" && &1.step > 5, do: &1))
            |> Enum.uniq()
            |> List.delete(nil)
      %{
        id: facility.id,
        facility_name: facility.name,
        facility_code: facility.code,
        pf_count: Enum.count(fpf),
        facility_status: facility.status,
        facility_address1: Enum.join([facility.line_1, facility.line_2], " "),
        facility_address2: Enum.join([facility.city, facility.postal_code, facility.province], " "),
        facility_phone_no: facility.phone_no,
        latitude: facility.latitude,
        longitude: facility.longitude,
        practitioner: render_one(facility, MemberLinkWeb.SearchView, "facility.json", as: :facility)
      }
    end
  end

  def render("practitioner_specializations.json", %{practitioner_specializations: practitioner_specializations}) do
    ps = Enum.filter(practitioner_specializations, &(&1.type == "Primary"))
    List.first(ps).specialization.name
  end

  def render("facility.json", %{facility: facility}) do
    fpf =
      facility.practitioner_facilities
      |> Enum.map(& (if &1.practitioner_status.value == "Affiliated" && &1.step > 5, do: &1))
      |> Enum.uniq()
      |> List.delete(nil)
      facilities = for pf <- fpf do
        for ps <- pf.practitioner.practitioner_specializations do
          if is_nil(pf.practitioner_facility_contacts) do
            %{
              facility_id: facility.id,
              practitioner_id: pf.practitioner.id,
              facility_name: facility.name,
              practitioner_name: Enum.join([pf.practitioner.last_name, ", ", pf.practitioner.first_name]),
              status: pf.practitioner_status.value,
              f_status: facility.status,
              p_status: pf.practitioner.status,
              specialization: render_one(pf.practitioner.practitioner_specializations, MemberLinkWeb.SearchView,
                                         "practitioner_specializations.json", as: :practitioner_specializations),
              phones: "",
              schedule: render_many(pf.practitioner_schedules, MemberLinkWeb.SearchView, "practitioner_schedules.json", as: :practitioner_schedules),
              specialization_id: ps.id
            }
          else
            %{
              facility_id: facility.id,
              practitioner_id: pf.practitioner.id,
              facility_name: facility.name,
              practitioner_name: Enum.join([pf.practitioner.last_name, ", ", pf.practitioner.first_name]),
              status: pf.practitioner_status.value,
              f_status: facility.status,
              specialization: ps.specialization.name,
              phones: get_contact_number(pf.practitioner_facility_contacts),
              schedule: render_many(pf.practitioner_schedules, MemberLinkWeb.SearchView, "practitioner_schedules.json", as: :practitioner_schedules),
              specialization_id: ps.id
            }
          end
        end
      end
    facilities |> List.flatten()
  end

  def render("practitioner_schedules.json", %{practitioner_schedules: practitioner_schedule}) do
    %{
      day: practitioner_schedule.day,
      room: practitioner_schedule.room,
      time_from: practitioner_schedule.time_from,
      time_to: practitioner_schedule.time_to
    }
  end

  def render("practitioner.json", %{practitioners: practitioners}) do
    fpf =
      practitioners
      |> Enum.map(& (if &1.practitioner_status.value == "Affiliated" && &1.step > 5, do: &1))
      |> Enum.uniq()
      |> List.delete(nil)
    practitioners = for pf <- fpf do
      for ps <- pf.practitioner.practitioner_specializations do
        %{
          practitioner_id: pf.practitioner_id,
          facility_id: pf.facility_id,
          facility_name: pf.facility.name,
          latitude: pf.facility.latitude,
          longitude: pf.facility.longitude,
          facility_phone_no: pf.facility.phone_no,
          facility_code: pf.facility.code,
          facility_address1: Enum.join([pf.facility.line_1, pf.facility.line_2], " "),
          facility_address2: Enum.join([pf.facility.city, pf.facility.postal_code, pf.facility.province], " "),
          practitioner_name: pf.practitioner.last_name <> ", " <> pf.practitioner.first_name,
          status: pf.practitioner_status.value,
          f_status: pf.facility.status,
          p_status: pf.practitioner.status,
          specialization: ps.specialization.name,
          schedule: render_many(pf.practitioner_schedules, MemberLinkWeb.SearchView, "practitioner_schedules.json", as: :practitioner_schedules),
          specialization_id: ps.id
        }
      end
    end
    practitioners
    |> List.flatten()
  end

  def render("search_practitioner.json", %{practitioners: practitioners}) do
    practitioners = for ps <- practitioners do
      fpf =
        ps.practitioner.practitioner_facilities
        |> Enum.map(& (if &1.practitioner_status.value == "Affiliated" && &1.step > 5 && (&1.facility.type.value == "HB" || &1.facility.type.value == "CB"), do: &1))
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.flatten()
        for pf <- fpf do
          %{
            practitioner_id: pf.practitioner_id,
            facility_id: pf.facility_id,
            facility_name: pf.facility.name,
            latitude: pf.facility.latitude,
            longitude: pf.facility.longitude,
            facility_phone_no: pf.facility.phone_no,
            facility_code: pf.facility.code,
            facility_address1: Enum.join([pf.facility.line_1, pf.facility.line_2], " "),
            facility_address2: Enum.join([pf.facility.city, pf.facility.postal_code, pf.facility.province], " "),
            practitioner_name: pf.practitioner.last_name <> ", " <> pf.practitioner.first_name,
            status: pf.practitioner_status.value,
            f_status: pf.facility.status,
            p_status: pf.practitioner.status,
            specialization: ps.specialization.name,
            schedule: render_many(pf.practitioner_schedules, MemberLinkWeb.SearchView, "practitioner_schedules.json", as: :practitioner_schedules),
            specialization_id: ps.id
          }
        end
    end
    practitioners
    |> List.flatten()
  end

  def render("request_practitioner.json", %{practitioner: practitioner, facility: facility}) do
    %{
      practitioner_name: practitioner.last_name <> ", " <> practitioner.first_name,
      specialization: render_one(practitioner.practitioner_specializations, MemberLinkWeb.SearchView,
                                 "practitioner_specializations.json", as: :practitioner_specializations),
      facility_name: facility.name,
      facility_phone_no: facility.phone_no,
    }
  end

  def render("authorzation.json", %{authorization: authorization, transaction_id: transaction_id}) do
    %{
      id: authorization.authorization_id,
      transaction_id: transaction_id
    }
  end

  def render("loa_checker.json", %{checker: checker}) do
    %{
      consult: checker.consult,
      lab: checker.lab,
      acu: checker.acu
    }
  end

  def render("facility_intellisense.json", %{facilities: facilities}) do
    for facility <- facilities do
      %{
        name: facility.name,
        facility_address1: Enum.join([facility.line_1, facility.line_2], " "),
        facility_address2: Enum.join([facility.city, facility.postal_code, facility.province], " ")
      }
    end
  end

  def render("doctor_intellisense.json", %{practitioner_facilities: pfs})do
    for pf <- pfs do
      %{
        name: Enum.join([pf.practitioner.last_name, ", ", pf.practitioner.first_name]),
        facility_address1: Enum.join([pf.facility.line_1, pf.facility.line_2], " "),
        facility_address2: Enum.join([pf.facility.city, pf.facility.postal_code, pf.facility.province], " ")
      }
    end
  end

  def render("procedures.json", %{procedures: procedures})do
    for procedure <- procedures do
      %{
        procedure: procedure.procedure.description
      }
    end
  end

  def age(%Ecto.Date{day: d, month: m, year: y}, as_of \\ :now) do
    do_age({y, m, d}, as_of)
  end

  def do_age(birthday, :now) do
    {today, _time} = :calendar.now_to_datetime(:erlang.now)
    calc_diff(birthday, today)
  end

  def do_age(birthday, date), do: calc_diff(birthday, date)

  def calc_diff({y1, m1, d1}, {y2, m2, d2}) when m2 > m1 or (m2 == m1 and d2 >= d1) do
    y2 - y1
  end

  def calc_diff({y1, _, _}, {y2, _, _}), do: (y2 - y1) - 1

end
