defmodule MemberLinkWeb.Api.V1.LoaView do
  use MemberLinkWeb, :view

  def render("list_loa.json", %{loa: loa}) do
    %{
      loa: render_many(loa, MemberLinkWeb.Api.V1.LoaView, "loa.json", as: :loa)
    }
  end

  def render("loa.json", %{loa: loa}) do
    if is_nil(loa.coverage) == false do
    %{
      transaction_id: loa.transaction_no,
      id: loa.id,
      number: loa.number,
      request_datetime: loa.inserted_at,
      admission_datetime: loa.admission_datetime,
      discharge_datetime: nil,
      coverage: loa.coverage.name,
      validated: true,
      status: loa.status,
      chief_complaint: loa.chief_complaint,
      chief_complaint_others: loa.chief_complaint_others,
      amount: render_one(loa.authorization_amounts, MemberLinkWeb.Api.V1.LoaView, "amount.json", as: :amount),
      provider: render_one(loa.facility, MemberLinkWeb.Api.V1.LoaView, "provider.json", as: :provider),
      doctor: render_many(loa.authorization_practitioner_specializations, MemberLinkWeb.Api.V1.LoaView, "doctor.json", as: :doctor),
      diagnosis: render_many(loa.authorization_diagnosis, MemberLinkWeb.Api.V1.LoaView, "authorization_diagnosis.json", as: :authorization_diagnosis)
    }
    else
      %{
        transaction_id: loa.transaction_no,
        id: loa.id,
        number: loa.number,
        request_datetime: loa.inserted_at,
        admission_datetime: loa.admission_datetime,
        discharge_datetime: nil,
        coverage: nil,
        validated: true,
        status: loa.status,
        chief_complaint: loa.chief_complaint,
        chief_complaint_others: loa.chief_complaint_others,
        amount: render_one(loa.authorization_amounts, MemberLinkWeb.Api.V1.LoaView, "amount.json", as: :amount),
        provider: render_one(loa.facility, MemberLinkWeb.Api.V1.LoaView, "provider.json", as: :provider),
        doctor: render_many(loa.authorization_practitioner_specializations, MemberLinkWeb.Api.V1.LoaView, "doctor.json", as: :doctor),
        diagnosis: render_many(loa.authorization_diagnosis, MemberLinkWeb.Api.V1.LoaView, "authorization_diagnosis.json", as: :authorization_diagnosis)
      }
    end
  end

  def render("authorization_diagnosis.json", %{authorization_diagnosis: authorization_diagnosis}) do
    %{
      code: authorization_diagnosis.diagnosis.code,
      type: authorization_diagnosis.diagnosis.type,
      group_description: authorization_diagnosis.diagnosis.group_description,
      description: authorization_diagnosis.diagnosis.description,
      congenital: authorization_diagnosis.diagnosis.congenital,
      exclusion_type: authorization_diagnosis.diagnosis.exclusion_type
    }
  end

  def render("amount.json", %{amount: amount}) do
    %{
      member_pays: amount.member_covered,
      payor_pays: amount.payor_covered,
      company_pays: amount.company_covered,
      total: amount.consultation_fee
    }
  end

  def render("provider.json", %{provider: provider}) do
    %{
      id: provider.id,
      name: provider.name
    }
  end

  def render("doctor.json", %{doctor: doctor}) do
    %{
      id: doctor.practitioner_specialization.practitioner.id,
      name: Enum.join([doctor.practitioner_specialization.practitioner.first_name, doctor.practitioner_specialization.practitioner.middle_name, doctor.practitioner_specialization.practitioner.last_name], "  "),
      prc_no: doctor.practitioner_specialization.practitioner.prc_no,
      specialization: render_one(doctor.practitioner_specialization, MemberLinkWeb.Api.V1.DoctorView, "practitioner_specializations.json", as: :practitioner_specializations),
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

  def render("loa_checker.json", %{checker: checker}) do
    %{
      consult: checker.consult,
      lab: checker.lab
    }
  end

end
