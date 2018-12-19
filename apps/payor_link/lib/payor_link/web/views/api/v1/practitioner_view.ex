defmodule Innerpeace.PayorLink.Web.Api.V1.PractitionerView do
  use Innerpeace.PayorLink.Web, :view
  alias Innerpeace.Db.Base.DropdownContext

  def render("index.json", %{practitioners: practitioners}) do
    %{data: render_many(practitioners,
      Innerpeace.PayorLink.Web.Api.V1.PractitionerView,
      "practitioners3.json", as: :practitioners)}
  end

  def render("show.json", %{practitioners: practitioners}) do
    %{data: render_one(practitioners,
      Innerpeace.PayorLink.Web.Api.V1.PractitionerView,
        "practitioners.json", as: :practitioners)}
  end

  def render("practitioners3.json", %{practitioners: practitioners}) do

    %{
      id: practitioners.id,
      first_name: practitioners.first_name,
      middle_name: practitioners.middle_name,
      last_name: practitioners.last_name,
      birth_date: practitioners.birth_date,
      effectivity_from: practitioners.effectivity_from,
      effectivity_to: practitioners.effectivity_to,
      suffix: practitioners.suffix,
      gender: practitioners.gender,
      affiliated: practitioners.affiliated,
      prc_no: practitioners.prc_no,
      type: practitioners.type,
      step: practitioners.step,
      code: practitioners.code,
      status: practitioners.status,
      exclusive: practitioners.exclusive,
      vat_status: practitioners.vat_status,
      prescription_period: practitioners.prescription_period,
      tin: practitioners.tin,
      withholding_tax: practitioners.withholding_tax,
      payment_type: practitioners.payment_type,
      xp_card_no: practitioners.xp_card_no,
      payee_name: practitioners.payee_name,
      account_no: practitioners.account_no,
      bank:
        render_one(practitioners.bank,
          Innerpeace.PayorLink.Web.Api.V1.PractitionerView,
          "practitioner_bank.json", as: :practitioner_bank),
      contacts:
        render_one(practitioners.practitioner_contact,
          Innerpeace.PayorLink.Web.Api.V1.PractitionerView,
          "practitioner_contact.json", as: :practitioner_contact),
      facility:
        render_one(practitioners.practitioner_facilities,
          Innerpeace.PayorLink.Web.Api.V1.PractitionerView,
          "practitioner_facility.json", as: :practitioner_facilities),
      specialization:
        render_one(practitioners.practitioner_specializations,
          Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "practitioner_specialization.json",
            as: :practitioner_specializations),
      account_group:
        render_one(practitioners.practitioner_accounts,
          Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "practitioner_accounts.json",
            as: :practitioner_accounts)
    }
  end

  def render("practitioner_contact.json", %{practitioner_contact: practitioner_contact}) do
    %{
      emails: render_many(practitioner_contact.contact.emails,
        Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "emails.json", as: :emails),
      phones: render_many(practitioner_contact.contact.phones,
        Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "phones.json", as: :phones)
    }
  end

  def render("practitioner_bank.json", %{practitioner_bank: practitioner_bank}) do
    %{
      bank_name: practitioner_bank.account_name,
      bank_no: practitioner_bank.account_no,
      status: practitioner_bank.status,
      branch: practitioner_bank.branch
    }
  end

  def render("practitioners.json", %{practitioners: practitioners}) do
    %{
      id: practitioners.id,
      first_name: practitioners.first_name,
      middle_name: practitioners.middle_name,
      last_name: practitioners.last_name,
      birth_date: practitioners.birth_date,
      effectivity_from: practitioners.effectivity_from,
      effectivity_to: practitioners.effectivity_to,
      suffix: practitioners.suffix,
      gender: practitioners.gender,
      affiliated: practitioners.affiliated,
      prc_no: practitioners.prc_no,
      type: practitioners.type,
      step: practitioners.step,
      code: practitioners.code,
      status: practitioners.status,
      exclusive: practitioners.exclusive,
      vat_status: practitioners.vat_status,
      prescription_period: practitioners.prescription_period,
      tin: practitioners.tin,
      withholding_tax: practitioners.withholding_tax,
      payment_type: practitioners.payment_type,
      xp_card_no: practitioners.xp_card_no,
      payee_name: practitioners.payee_name,
      account_no: practitioners.account_no,
      bank: render_one(practitioners.practitioner_banks,
        Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "practitioner_bank.json",
          as: :practitioner_banks),
      contacts: render_one(practitioners.practitioner_contacts,
        Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "practitioner_contacts.json",
          as: :practitioner_contacts),
      facility: render_one(practitioners.practitioner_facilities,
        Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "practitioner_facility.json",
          as: :practitioner_facilities),
      specializations: render_many(practitioners.practitioner_specializations,
        Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "practitioner_specializations.json",
          as: :practitioner_specializations),
      account_group: render_one(practitioners.practitioner_accounts,
        Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "practitioner_accounts.json",
          as: :practitioner_accounts)
    }
  end

  def render("practitioner_accounts.json", %{practitioner_accounts: practitioner_accounts}) do

    for practitioner_account <- practitioner_accounts do
      %{
        name: practitioner_account.account_group.name,
        code: practitioner_account.account_group.code,
        type: practitioner_account.account_group.type,
        description: practitioner_account.account_group.description,
        segment: practitioner_account.account_group.segment,
        phone_no: practitioner_account.account_group.phone_no,
        email: practitioner_account.account_group.email,
        remarks: practitioner_account.account_group.remarks,
        mode_of_payment: practitioner_account.account_group.mode_of_payment,
        payee_name: practitioner_account.account_group.payee_name,
        account_no: practitioner_account.account_group.account_no,
        account_name: practitioner_account.account_group.account_name,
        branch: practitioner_account.account_group.branch
      }
    end
  end

  def render("practitioner_bank.json", %{practitioner_banks: practitioner_banks}) do
    for practitioner_bank <- practitioner_banks do
      %{
        account_name: practitioner_bank.account_name,
        account_no: practitioner_bank.account_no,
        status: practitioner_bank.status,
        branch: practitioner_bank.branch
      }
    end
  end

  def render("practitioner_facility.json", %{practitioner_facilities: practitioner_facilities}) do
    for practitioner_facility <- practitioner_facilities do
      %{
        name: practitioner_facility.facility.name,
        code: practitioner_facility.facility.code,
        license_name: practitioner_facility.facility.license_name,
        phic_accreditation_from:
          practitioner_facility.facility.phic_accreditation_from,
        phic_accreditation_to:
          practitioner_facility.facility.phic_accreditation_to,
        phic_accreditation_no:
          practitioner_facility.facility.phic_accreditation_no,
        status: practitioner_facility.facility.status,
        affiliation_date: practitioner_facility.facility.affiliation_date,
        disaffiliation_date: practitioner_facility.facility.disaffiliation_date,
        phone_no: practitioner_facility.facility.phone_no,
        website: practitioner_facility.facility.website,
        line_1: practitioner_facility.facility.line_1,
        line_2: practitioner_facility.facility.line_2,
        city: practitioner_facility.facility.city,
        province: practitioner_facility.facility.province,
        region: practitioner_facility.facility.region,
        country: practitioner_facility.facility.country,
        postal_code: practitioner_facility.facility.postal_code,
        longitude: practitioner_facility.facility.longitude,
        latitude: practitioner_facility.facility.latitude,
        tin: practitioner_facility.facility.tin,
        credit_term: practitioner_facility.facility.credit_term,
        credit_limit: practitioner_facility.facility.credit_limit,
        no_of_beds: practitioner_facility.facility.no_of_beds,
        bond: practitioner_facility.facility.bond,
        step: practitioner_facility.facility.step,
        practitioner_schedules:
          render_many(practitioner_facility.practitioner_schedules,
            Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "practitioner_schedules.json",
              as: :practitioner_schedules),
        id: practitioner_facility.facility.id
      }
    end
  end

  def render("practitioner_specializations.json", %{practitioner_specializations: practitioner_specializations}) do
      %{
        practitioner_specialization_id: practitioner_specializations.id,
        id: practitioner_specializations.specialization.id,
        name: practitioner_specializations.specialization.name,
        type: practitioner_specializations.type
      }
  end

  def render("practitioner_specialization.json", %{practitioner_specializations: practitioner_specializations}) do
    for practitioner_specialization <- practitioner_specializations do
      %{
        practitioner_specialization_id: practitioner_specialization.id,
        id: practitioner_specialization.specialization.id,
        name: practitioner_specialization.specialization.name,
        type: practitioner_specialization.type
      }
    end
  end

  def render("practitioner_contacts.json", %{practitioner_contacts: practitioner_contacts}) do
    for practitioner_contact <- practitioner_contacts do
      %{
        type: practitioner_contact.contact.type,
        last_name: practitioner_contact.contact.last_name,
        department: practitioner_contact.contact.department,
        designation: practitioner_contact.contact.designation,
        email: practitioner_contact.contact.email,
        ctc_number: practitioner_contact.contact.ctc,
        ctc_date_issued: practitioner_contact.contact.ctc_date_issued,
        ctc_place_issued: practitioner_contact.contact.ctc_place_issued,
        passport_number: practitioner_contact.contact.passport_no,
        passport_date_issued: practitioner_contact.contact.passport_date_issued,
        passport_place_issued:
          practitioner_contact.contact.passport_place_issued,
        emails:
          render_many(practitioner_contact.contact.emails,
            Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "emails.json", as: :emails),
        phones:
          render_many(practitioner_contact.contact.phones,
            Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "phones.json", as: :phones)
      }
    end
  end

  def render("emails.json", %{emails: emails}) do
    %{
      address: emails.address,
      type: "email"
    }
  end

  def render("phones.json", %{phones: phones}) do
    %{
      type: phones.type,
      number: phones.number,
      country_code: phones.country_code,
      area_code: phones.area_code,
      local: phones.local

    }
  end

  def render("practitioner_schedules.json", %{practitioner_schedules: practitioner_schedules}) do
    %{
      id: practitioner_schedules.id,
      day: practitioner_schedules.day,
      room: practitioner_schedules.room,
      time_from: practitioner_schedules.time_from,
      time_to: practitioner_schedules.time_to
    }
  end

  #### temporary show json for post api practitioner/new
  def render("show2.json", %{practitioner: practitioner}) do
    %{data: render_one(practitioner,
      Innerpeace.PayorLink.Web.Api.V1.PractitionerView,
        "practitioners2.json", as: :practitioner)}
  end

  def render("practitioners2.json", %{practitioner: practitioner}) do
    %{
      id: practitioner.id,
      code: practitioner.code,
      first_name: practitioner.first_name,
      middle_name: practitioner.middle_name,
      last_name: practitioner.last_name,
      birth_date: practitioner.birth_date,
      suffix: practitioner.suffix,
      gender: practitioner.gender,
      affiliated: practitioner.affiliated,
      prc_no: practitioner.prc_no,
      status: practitioner.status,
      effectivity_from: practitioner.effectivity_from,
      effectivity_to: practitioner.effectivity_to,
      exclusive: practitioner.exclusive,
      vat_status: practitioner.vat_status,
      prescription_period: practitioner.prescription_period,
      tin: practitioner.tin,
      withholding_tax: practitioner.withholding_tax,
      payment_type: practitioner.payment_type,
      xp_card_no: practitioner.xp_card_no,
      payee_name: practitioner.payee_name,
      account_no: practitioner.account_no,
      exclusive: practitioner.exclusive,
      bank: payment_type_checker(practitioner),

      ## reusing existing json for rendering
      specialization:
        render_one(practitioner.practitioner_specializations,
          Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "practitioner_specialization.json",
            as: :practitioner_specializations),

      ## new render many for list of contact
      practitioner_facility:
        render_one(practitioner.practitioner_facilities,
          Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "post_practitioner_facility.json",
            as: :practitioner_facilities),
      contacts:
        render_one(practitioner.practitioner_contact,
          Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "post_practitioner_contacts.json",
            as: :practitioner_contact),

    }
  end

  def render("post_practitioner_contacts.json", %{practitioner_contact: practitioner_contact}) do
       %{
         emails:
          render_many(practitioner_contact.contact.emails,
            Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "emails.json", as: :emails),
         phones:
          render_many(practitioner_contact.contact.phones,
            Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "phones.json", as: :phones)
       }
  end

  def render("post_practitioner_facility_contacts.json", %{practitioner_facility_contact: practitioner_facility_contact}) do
    %{
      emails:
        render_many(practitioner_facility_contact.contact.emails,
          Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "emails.json", as: :emails),
      phones:
        render_many(practitioner_facility_contact.contact.phones,
          Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "phones.json", as: :phones)
    }
  end

  def render("post_practitioner_facility.json", %{practitioner_facilities: practitioner_facilities}) do
    for practitioner_facility <- practitioner_facilities do
      %{
        name: practitioner_facility.facility.name,
        code: practitioner_facility.facility.code,
        practitioner_type:
          render_many(
            practitioner_facility.practitioner_facility_practitioner_types,
            Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "practitioner_types.json", as: :types),
        pf_status:
          DropdownContext.get_practitioner_status_by_id(
            practitioner_facility.pstatus_id),
        affiliation_date: practitioner_facility.affiliation_date,
        disaffiliation_date: practitioner_facility.disaffiliation_date,
        payment_mode: practitioner_facility.payment_mode,
        credit_term: practitioner_facility.credit_term,
        practitioner_facility_contacts:
          render_one(practitioner_facility.practitioner_facility_contacts,
            Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "post_practitioner_facility_contacts.json",
              as: :practitioner_facility_contact),
        coordinator: practitioner_facility.coordinator,
        consultation_fee: practitioner_facility.consultation_fee,
        coordinator_fee: practitioner_facility.coordinator_fee,
        cp_clearance_name:
          DropdownContext.get_cp_clearance_by_id(
            practitioner_facility.cp_clearance_id),
        cp_clearance_rate: practitioner_facility.cp_clearance_rate,
        fixed: practitioner_facility.fixed,
        fixed_fee: practitioner_facility.fixed_fee,
        schedule:
          render_many(practitioner_facility.practitioner_schedules,
            Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "post_practitioner_facility_schedules.json",
              as: :practitioner_schedule),
        pf_room_rate:
          render_many(practitioner_facility.practitioner_facility_rooms,
            Innerpeace.PayorLink.Web.Api.V1.PractitionerView, "post_practitioner_facility_rooms.json",
              as: :practitioner_room_rate)
      }
    end
  end

  def render("post_practitioner_facility_rooms.json", %{practitioner_room_rate: practitioner_room_rate}) do

    params =  %{
      rate: practitioner_room_rate.rate,
      facility_room_type:
        practitioner_room_rate.facility_room.facility_room_type
    }
  end

  def render("post_practitioner_facility_schedules.json", %{practitioner_schedule: practitioner_schedule}) do
    %{
      day: practitioner_schedule.day,
      room:  practitioner_schedule.room,
      time_from: practitioner_schedule.time_from,
      time_to: practitioner_schedule.time_to
    }
  end

  def render("practitioner_types.json", %{types: types}) do
    %{
      type: types.type
    }
  end

  def payment_type_checker(practitioner) do
    if practitioner.payment_type != "Bank" do
      nil
    else
      practitioner.bank.account_name
    end
  end

  def render("vendor_code.json", %{code: code}) do
    %{code: code}
  end

end
