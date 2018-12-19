defmodule Innerpeace.Db.Base.Api.Vendor.AuthorizationContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false

  alias Guardian.Plug
  alias Ecto.Changeset
  alias Ecto.DateTime
  alias Timex.Duration
  alias Innerpeace.Db.Repo

  alias Innerpeace.Db.Base.Api.{
    Vendor.DiagnosisContext
  }

  alias Innerpeace.Db.Base.{
    AuthorizationContext,
    AcuScheduleContext,
    DiagnosisContext,
    MemberContext,
    FacilityContext,
    Api.UtilityContext,
    PractitionerContext,
    CoverageContext,
    ProductContext,
    BatchContext,
    ProcedureContext
  }

  alias Innerpeace.Db.Schemas.{
    Authorization,
    Facility,
    Practitioner,
    Diagnosis,
    Member,
    Coverage,
    PractitionerSpecialization,
    AuthorizationPractitionerSpecialization,
    AuthorizationProcedureDiagnosis,
    AuthorizationAmount
  }

  alias Innerpeace.Db.Validators.OPConsultValidator
  alias Innerpeace.PayorLink.Web.Api.V1.Vendor.AuthorizationView
  alias Innerpeace.PayorLink.Web.Api.V1.ErrorView

  alias Innerpeace.PayorLink.Web.Api.V1.AuthorizationController,
    as: AuthorizationControllerAPI

  alias Innerpeace.Db.Base.Api.PractitionerContext,
    as: PractitionerContextAPI

  def validate_required_consult(params) do
    cond do
      is_nil(params["member_id"]) ->
        {:error, "Please enter a member"}
      is_nil(params["card_number"]) ->
        {:error, "Please enter card number"}
      is_nil(params["practitioner_specialization_id"]) ->
        {:error, "Please enter a practitioner specialization"}
      is_nil(params["facility_id"]) ->
        {:error, "Please enter a facility"}
      true ->
        validate_required2_consult(params)
    end
  end

  def validate_required2_consult(params) do
    cond do
      is_nil(params["diagnosis_id"]) ->
        {:error, "Please enter diagnosis"}
      is_nil(params["datetime"]) ->
        {:error, "Please enter date time"}
      is_nil(params["consultation_type"]) ->
        {:error, "Please enter consultation type"}
      is_nil(params["origin"]) ->
        {:error, "Please enter origin"}
      is_nil(params["chief_complaint"]) ->
        {:error, "Please enter chief complaint"}
      true ->
        {:valid}
    end
  end

  def check_practitioner_specialization_consult(practitioner_specialization_id) do
    if UtilityContext.valid_id?(practitioner_specialization_id) do
      practitioner_specialization = PractitionerContext.get_practitioner_specializations(practitioner_specialization_id)
      if not is_nil(practitioner_specialization) do
        {:ok, practitioner_specialization}
      else
        {:error, "Practitioner Specialization does not exist"}
      end
    else
      {:error, "Invalid Practitioner Specialization ID"}
    end
  end

  def check_facility_consult(facility_id) do
    if UtilityContext.valid_id?(facility_id) do
      facility = FacilityContext.get_facility(facility_id)
      cond do
        is_nil(facility) ->
          {:error, "Facility does not exist."}
        facility.status != "Affiliated" ->
          {:error, "Facility not affiliated"}
        true ->
          {:ok, FacilityContext.get_facility(facility_id)}
      end
      else
        {:error, "Invalid Facility ID"}
    end
  end

  def check_diagnosis_consult(diagnosis_id) do
    if UtilityContext.valid_id?(diagnosis_id) do
      diagnosis = DiagnosisContext.get_diagnosis(diagnosis_id)
      if not is_nil(diagnosis) do
        {:ok, diagnosis}
      else
        {:error, "Diagnosis does not exist"}
      end
    else
      {:error, "Invalid Diagnosis ID"}
    end
  end

  def validate_card_number_consult(card_number) do
    cond do
      Regex.match?(~r/^[0-9]*$/, card_number) == false ->
        {:error, "Card number should be numberic only"}
      String.length(card_number) != 16 ->
        {:error, "Card number should be 16-digits"}
      true ->
        get_member_by_card_number(card_number)
    end
  end

  def validate_member_consult(member_id) do
    if UtilityContext.valid_id?(member_id) do
      member = MemberContext.get_member(member_id)
      if not is_nil(member) do
        {:ok, member}
      else
        {:error, "Member does not exist"}
      end
    else
      {:error, "Invalid Member ID"}
    end
  end

  def validate_member_card_consult(member_id, card_number) do
    member = MemberContext.get_member_by_id_and_card_number(member_id, card_number)

    if not is_nil(member) do
      {:valid}
    else
      {:error, "Card number not affiliated with member"}
    end
  end

  def validate_consultation_type_consult(consultation_type) do
    consultation_type = String.downcase(consultation_type)
    if consultation_type != "initial" and consultation_type != "follow up" and consultation_type != "clearance" do
      {:error, "Invalid Consultation Type"}
    else
      {:valid}
    end
  end

  def validate_origin_consult(origin) do
    if Enum.member?(valid_origins(), origin) do
      {:valid}
    else
      {:error, "Invalid Origin"}
    end
  end

  def valid_origins do
    [
      "accountlink",
      "doctorlink",
      "memberlink" ,
      "payorlink",
      "providerlink"
    ]
  end

  def validate_ps_consultation_fee_consult(facility_id, ps_id) do
    ps = PractitionerContext.get_specialization_consultation_fee(facility_id, ps_id)
    if is_nil(ps) do
      {:error, "Practitioner Specialization has no consultation fee"}
    else
      {:ok}
    end
  end

  def get_member_by_card_number(card_number) do
    if is_nil(MemberContext.get_member_by_card_no(card_number)) do
      {:error, "Card Number does not exist"}
    else
      {:ok, MemberContext.get_member_by_card_no(card_number)}
    end
  end

  def validate_practitioner_specialization(practitioner_code, specialization) do
    ps = PractitionerContextAPI.get_practitioner_by_code(practitioner_code)
    if is_nil(ps) do
      {:error, "Practitioner not found"}
    else
      has_specialization = Enum.find(ps.practitioner_specializations, fn(x) ->
        x.specialization.name == specialization
      end)

      if is_nil(has_specialization) do
        {:error, "Practitioner do not cover #{specialization}"}
      else
        {:ok, PractitionerContext.get_ps_by_id(ps.id, has_specialization.specialization.id)}
      end
    end
  end

  def validate_facility(code) do
    if is_nil(FacilityContext.get_facility_by_code(code)) do
      {:error, "Facility not found"}
    else
      {:ok, FacilityContext.get_facility_by_code(code)}
    end
  end

  def validate_diagnosis_code(params) do
    if Map.has_key?(params, "consultation_type") do
      case String.downcase(params["consultation_type"]) do
        "initial" ->
          {:ok, get_diagnosis("Z71.1")}
        "follow up" ->
          get_diagnosis(params, [])
        "clearance" ->
          get_diagnosis(params, [])
      end
      else
        {:error, "Consultation Type is required"}
    end
  end

  def get_diagnosis(params, []) do
    diagnosis_code = if Map.has_key?(params, "diagnosis_code") do
      if is_nil(get_diagnosis(params["diagnosis_code"])) do
        {:error, "Diagnosis not found"}
      else
        {:ok, get_diagnosis(params["diagnosis_code"])}
      end
    else
      {:error, "Diagnosis Code is required"}
    end
  end

  def get_diagnosis(code) do
    DiagnosisContext.get_diagnosis_by_code(code)
  end

  def op_consult_validate_required(params) do
    cond do
      is_nil(params["coverage"]) ->
        {:error, "Please enter a coverage"}
      is_nil(params["card_number"]) ->
        {:error, "Please enter card number"}
      is_nil(params["practitioner_code"]) ->
        {:error, "Please enter a practitioner code"}
      is_nil(params["practitioner_specialization"]) ->
        {:error, "Please enter a practitioner specialization"}
      true ->
        op_consult_validate_required2(params)
    end
  end

  def op_consult_validate_required2(params) do
    cond do
      is_nil(params["facility_code"]) ->
        {:error, "Please enter a facility code"}
      is_nil(params["service_date"]) ->
        {:error, "Please enter a service date"}
      is_nil(params["chief_complaint"]) ->
        {:error, "Please enter a chief complaint"}
      is_nil(params["copy"]) ->
        {:error, "Please enter a copy type"}
      true ->
        {:valid}
    end
  end

  def acu_validate_required(params) do
    cond do
      is_nil(params["service_date"]) ->
        {:error, "Please enter a service date"}
      is_nil(params["card_number"]) ->
        {:error, "Please enter a card number"}
      is_nil(params["facility_code"]) ->
        {:error, "Please enter a facility code"}
      is_nil(params["coverage"]) ->
        {:error, "Please enter a coverage"}
      true ->
        {:valid}
    end
  end

  def peme_validate_required(params) do
    cond do
      is_nil(params["service_date"]) ->
        {:error, "Please enter a service date"}
      is_nil(params["card_number"]) ->
        {:error, "Please enter a card number"}
      is_nil(params["facility_code"]) ->
        {:error, "Please enter a facility code"}
      is_nil(params["coverage"]) ->
        {:error, "Please enter a coverage"}
      true ->
        {:valid}
    end
  end

  def insert_oplab(changeset, user) do
    valid_until = Timex.add(Ecto.Date.utc(), Timex.Duration.from_days(2))
    facility = get_change(changeset, :facility)
    params = %{
      chief_complaint: get_change(changeset, :chief_complaint),
      total_amount: Decimal.new(1350),
      status: get_change(changeset, :status),
      admission_datetime: get_change(changeset, :admission_datetime),
      discharge_datetime: get_change(changeset, :discharge_datetime),
      valid_until: valid_until,
      origin: get_change(changeset, :origin),
      approved_datetime: get_change(changeset, :approved_datetime),
      facility_id: facility.id,
      coverage_id: get_change(changeset, :coverage_id),
      version: 1,
      member_id: get_change(changeset, :member_id),
      step: 5,
      created_by_id: user.id,
      updated_by_id: user.id,
      approved_by_id: user.id,
      discharge_datetime: get_change(changeset, :requested_datetime),
      transaction_no: AuthorizationContext.generate_transaction_no()
    }
    changeset = Authorization.vendor_oplab_changeset(%Authorization{}, params)
    Repo.insert(changeset)
  end

  def insert_oplab_amount(authorization) do
    params = %{
      payor_covered: Decimal.new(1350),
      member_covered: Decimal.new(0),
      company_covered: Decimal.new(0),
      total_amount: Decimal.new(1350),
      authorization_id: authorization.id,
      vat_amount: Decimal.new(0)
    }
    changeset =
      AuthorizationAmount.utilization_changeset(
        %AuthorizationAmount{},
        params
      )
    Repo.insert(changeset)
  end

  def insert_oplab_apds(authorization, changeset, aps) do
    procedure = get_change(changeset, :procedure)
    params = %{
      unit: Decimal.new(1),
      amount: Decimal.new(1350),
      member_pay: Decimal.new(0),
      payor_pay: Decimal.new(1350),
      philhealth_pay: Decimal.new(0),
      authorization_id: authorization.id,
      diagnosis_id: changeset.changes.diagnosis.id,
      authorization_practitioner_specialization_id: aps.id,
      payor_procedure_id: procedure.id,
      created_by_id: authorization.created_by_id,
      updated_by_id: authorization.created_by_id
    }
    changeset =
      AuthorizationProcedureDiagnosis.changeset(
        %AuthorizationProcedureDiagnosis{},
        params
      )
    Repo.insert(changeset)
  end

  def insert_aps(authorization, changeset) do
    practitioner = get_change(changeset, :practitioner)
    practitioner_specialization =
      Enum.find(practitioner.practitioner_specializations, fn(ps) ->
        ps.specialization.name == get_change(changeset, :practitioner_specialization)
      end)
    params = %{
      authorization_id: authorization.id,
      practitioner_specialization_id: practitioner_specialization.id,
      created_by_id: authorization.created_by_id,
      updated_by_id: authorization.created_by_id
    }
    changeset =
      AuthorizationPractitionerSpecialization.changeset(
        %AuthorizationPractitionerSpecialization{},
        params
      )
    Repo.insert(changeset)
  end

  def validate_oplab_params(params) do
    types = %{
      coverage: :string,
      card_number: :string,
      practitioner_code: :string,
      practitioner_specialization: :string,
      facility_code: :string,
      chief_complaint: :string,
      diagnosis_code: :string,
      procedure_code: :string,
      copy: :string
    }
    changeset =
      {%{}, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([
        :coverage,
        :card_number,
        :practitioner_code,
        :practitioner_specialization,
        :facility_code,
        :chief_complaint,
        :diagnosis_code,
        :procedure_code,
        :copy
      ], message: "is required")
      |> validate_inclusion(:copy, [
        "original",
        "duplicate"
      ], message: "is invalid")
      |> put_change(:origin, "payorlink")
      |> put_change(:coverage_id, get_coverage_id("OPL"))
      |> put_change(:discharge_datetime, Ecto.DateTime.utc())
      |> put_change(:admission_datetime, Ecto.DateTime.utc())
      |> put_change(:approved_datetime, Ecto.DateTime.utc())
      |> put_change(:requested_datetime, Ecto.DateTime.utc())
      |> put_change(:status, "Approved")
      |> validate_card_number()
      |> validate_practitioner_code()
      |> validate_practitioner_specialization()
      |> validate_facility_code()
      |> validate_diagnosis()
      |> validate_procedure_code()
    if Enum.empty?(changeset.errors) do
      {:ok, changeset}
    else
      {:changeset_error, UtilityContext.changeset_errors_to_string(changeset.errors)}
    end
  end

  defp get_coverage_id(code) do
    coverage = CoverageContext.get_coverage_by_code(code)
    coverage.id
  end

  defp validate_card_number(changeset) do
    with true <- Map.has_key?(changeset.changes, :card_number) do
      member = MemberContext.get_member_by_card_no(changeset.changes.card_number)
      if member do
        if member.status == "Active" do
          Changeset.put_change(changeset, :member_id, member.id)
        else
          Changeset.add_error(changeset, :card_number, "is inactive")
        end
      else
        Changeset.add_error(changeset, :card_number, "is invalid")
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_practitioner_code(changeset) do
    with true <- Map.has_key?(changeset.changes, :practitioner_code) do
      practitioner = PractitionerContextAPI.get_practitioner_by_code(changeset.changes.practitioner_code)
      if practitioner do
        Changeset.put_change(changeset, :practitioner, practitioner)
      else
        Changeset.add_error(changeset, :practitioner_code, "does not exist")
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_practitioner_specialization(changeset) do
    with true <- Map.has_key?(changeset.changes, :practitioner_specialization),
         true <- Map.has_key?(changeset.changes, :practitioner)
    do
      specializations =
        Enum.map(changeset.changes.practitioner.practitioner_specializations, fn(ps) ->
          ps.specialization.name
        end)
      if Enum.member?(specializations, changeset.changes.practitioner_specialization) do
        changeset
      else
        Changeset.add_error(
          changeset,
          :practitioner_specialization,
          "Practitioner do not cover #{changeset.changes.practitioner_specialization}"
        )
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_facility_code(changeset) do
    with true <- Map.has_key?(changeset.changes, :facility_code) do
      facility = FacilityContext.get_facility_by_code(changeset.changes.facility_code)
      if facility do
        Changeset.put_change(changeset, :facility, facility)
      else
        Changeset.add_error(changeset, :facility_code, "does not exist")
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_diagnosis(changeset) do
    with true <- Map.has_key?(changeset.changes, :diagnosis_code) do
      diagnosis = DiagnosisContext.get_diagnosis_by_code(changeset.changes.diagnosis_code)
      if diagnosis do
        Changeset.put_change(changeset, :diagnosis, diagnosis)
      else
        Changeset.add_error(changeset, :diagnosis_code, "does not exist")
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_procedure_code(changeset) do
    with true <- Map.has_key?(changeset.changes, :procedure_code) do
      procedure = ProcedureContext.get_payor_procedure_by_code(changeset.changes.procedure_code)
      if procedure do
        Changeset.put_change(changeset, :procedure, procedure)
      else
        Changeset.add_error(changeset, :procedure_code, "does not exist")
      end
    else
      _ ->
        changeset
    end
  end

  def validate_practitioner_vat(ps) do
    practitioner = PractitionerContext.get_practitioner(ps.practitioner_id)
    if is_nil(practitioner.vat_status_id) do
      {:error, "Practitioner doesn't have VAT Status yet"}
    else
      {:ok, practitioner}
    end
  end
end
