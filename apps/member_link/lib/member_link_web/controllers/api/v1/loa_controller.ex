defmodule MemberLinkWeb.Api.V1.LoaController do
  use MemberLinkWeb, :controller

  alias Guardian.Plug
  alias MemberLinkWeb.Api.ErrorView
  alias Innerpeace.Db.Base.{
    AuthorizationContext,
    DiagnosisContext,
    MemberContext,
    Api.KycContext,
    Api.UtilityContext,
    CoverageContext,
    PractitionerContext,
    FacilityContext
  }
  alias Innerpeace.Db.Validators.OPConsultValidator

  alias Innerpeace.Db.Parsers.MemberLinkParser,
  alias Innerpeace.Db.Schemas.{
    # Authorization,
    Facility,
    Practitioner,
    Diagnosis,
    # Embedded.OPLab
  }
  alias Innerpeace.Db.Validators.OPLabValidator
  alias MemberLink.Guardian, as: MG

  def request_op_lab(conn, params) do
    if params["datetime"] != "" do
      validate_datetime = params["datetime"]
                          |> UtilityContext.transform_datetime_request()
      if validate_datetime == {:invalid_datetime_format} do
        error_msg(conn, 400, "Invalid DateTime Format")
      else
        validate_datetime = validate_datetime
                            |> Ecto.DateTime.to_date()
        params = Map.put(params, "admission_datetime", validate_datetime)
      end
    end
    user = MG.current_resource_api(conn)
    with {:ok, changeset} <- OPLabValidator.validate_without_procedure_and_diagnosis(params),
         %Practitioner{} <- AuthorizationContext.get_practitioner_by_id(
            params["doctor_id"]),
         %Facility{} <- AuthorizationContext.get_provider_by_id(
            params["provider_id"]),
         {:validate_fee} <- AuthorizationContext.check_consultation_fee_and_affiliation_date(
            params["provider_id"], params["doctor_id"]),
         {:ok, datetime} <- UtilityContext.transform_datetime(
            params["datetime"]),
         {:ok, _member} <- MemberContext.loa_card_checker(params),
         true <- (MemberContext.get_member(params["member_id"])).products != [],
         {:ok, "uploads"} <- KycContext.validate_uploads(params["uploads"]),
         {:ok, op_lab} <- OPLabValidator.request_without_procedure_and_diagnosis(changeset, Map.merge(params, %{"datetime" => datetime, "user_id" => user.id})),
         {:ok, ap} <- AuthorizationContext.create_authorization_practitioner(%{
           "authorization_id" => op_lab.id,
           "practitioner_id" => params["doctor_id"]
         }, user.id),
         loa = AuthorizationContext.get_authorization_by_id(ap.authorization_id)
    do
      MemberLinkParser.upload_a_file_op_lab(loa.id, params["uploads"])
      render(conn, MemberLinkWeb.Api.V1.LoaView, "loa.json", loa: loa)
    else
      {:invalid_id, "provider"} ->
        error_msg(conn, 400, "Invalid Provider")
      {:invalid_id, "practitioner"} ->
        error_msg(conn, 400, "Invalid Doctor")
      {:invalid_id, "member"} ->
        error_msg(conn, 400, "Invalid Member")
      {:nil, "provider"} ->
        error_msg(conn, 400, "Provider Not Found")
      {:nil, "practitioner"} ->
        error_msg(conn, 400, "Doctor Not Found")
      {:invalid_provider_affiliation} ->
        error_msg(conn, 400, "Invalid Provider Affiliation")
      {:error_fee} ->
        error_msg(conn, 400, "Invalid Doctor Provider Affiliation")
      {:invalid_datetime_format} ->
        error_msg(conn, 400, "Invalid DateTime Format")
      {:card_number_is_invalid} ->
        error_msg(conn, 400, "No Card Number")
      {:not_found} ->
        error_msg(conn, 404, "Member Not Found")
      false  ->
        error_msg(conn, 404, "There's no Product in Member")
      {:error, "no_product"} ->
        error_msg(conn, 404, "No OP Laboratory coverage  in any Products")
      {:error_upload_params} ->
        error_msg(conn, 400, "Invalid Upload Parameters")
      {:error_base_64} ->
        error_msg(conn, 400, "Invalid Upload Base 64")
      {:error, changeset} ->
      raise changeset
        conn
        |> put_status(400)
        |> render(ErrorView, "changeset_error.json", changeset: changeset)
      _ ->
        error_msg(conn, 500, "Server Error")
    end
  end

  def request_op_consult(conn, params) do
    user = MG.current_resource_api(conn)
    diagnosis = DiagnosisContext.get_diagnosis_by_code("Z71.1")
    op_consult = CoverageContext.get_coverage_by_name("OP Consult")
    params = %{
      "facility_id" => params["provider_id"],
      "practitioner_specialization_id" => params["practitioner_specialization_id"],
      "chief_complaint" => "Others",
      "chief_complaint_others" => params["chief_complaint"],
      "member_id" => params["member_id"],
      "card_number" => params["card_number"],
      "diagnosis_id" => diagnosis.id,
      "consultation_type" => "initial",
      "datetime" => params["datetime"],
      "origin" => "memberlink"
    }
    with {:valid} <-
            validate_required(params),
         {:ok, ps} <-
            check_practitioner_specialization(params["practitioner_specialization_id"]),
         {:ok, facility} <-
            check_facility(params["facility_id"]),
         {:ok, diagnosis} <-
            check_diagnosis(params["diagnosis_id"]),
         {:ok, card_number} <-
            validate_card_number(params["card_number"]),
         {:ok, member} <-
            validate_member(params["member_id"]),
         {:valid} <-
            validate_member_card(member.id, card_number),
         {:valid} <-
            validate_origin(params["origin"]),
         {:valid} <-
            validate_consultation_type(params["consultation_type"]),
         {:ok, datetime} <-
            UtilityContext.transform_datetime(params["datetime"]),
         false <-
            Enum.empty?(member.products),
         {:ok_coverage} <-
            AuthorizationContext.validate_coverage(params),
         {:ok} <-
            validate_ps_consultation_fee(facility.id, ps.id),
         {:ok, authorization} <-
            AuthorizationContext.create_authorization_api(user.id,
              params = params |> Map.merge(%{"coverage_id" => op_consult.id})),
         {:ok, op_consult} <-
            OPConsultValidator.request(params =
              params |> Map.merge(%{"authorization_id" => authorization.id, "user_id" => user.id})),
         loa = AuthorizationContext.get_authorization_by_id(op_consult.changes.authorization_id)
    do
      render(conn, MemberLinkWeb.Api.V1.LoaView, "loa.json", loa: loa)
    else
      {:invalid_datetime_format} ->
        error_msg(conn, 400, "Invalid DateTime Format")
      {:error_coverage} ->
        error_msg(conn, 400, "There's no OP Consult Coverage in Any Product")
      true  ->
        error_msg(conn, 400, "There's no Product in Member")
      false  ->
        error_msg(conn, 400, "No Consultation Fee")
      {:error, message} ->
        error_msg(conn, 400, message)
      _ ->
        error_msg(conn, 500, "Server Error")
    end
  end

  def get_loa(conn, _params) do
    user = MG.current_resource_api(conn)
    case AuthorizationContext.get_loa_using_member_id(user.member_id) do
      {:ok, loa} ->
        render(conn, MemberLinkWeb.Api.V1.LoaView, "list_loa.json", loa: loa)
      {:error, "loa"} ->
        error_msg(conn, 404, "No Loas Found")
      _ ->
        error_msg(conn, 500, "Server Error")
    end
  end

  def check_benefit_coverage(conn, _params) do
    user = MG.current_resource_api(conn)
    op_consult = CoverageContext.get_coverage_by_name("OP Consult")
    op_lab = CoverageContext.get_coverage_by_name("OP Laboratory")
    checker_consult = AuthorizationContext.check_coverage_in_product(user.member_id, op_consult.id)
    checker_lab = AuthorizationContext.check_coverage_in_product(user.member_id, op_lab.id)
    params = %{}
    if Enum.empty?(checker_consult) do
      params =
       Map.put_new(params, :consult, false)
    else
      params =
       Map.put_new(params, :consult, true)
    end
    if Enum.empty?(checker_lab) do
      params =
       Map.put_new(params, :lab, false)
    else
      params =
       Map.put_new(params, :lab, true)
    end
      render(conn, "loa_checker.json", checker: params)
  end

  defp error_msg(conn, status, message) do
    conn
    |> put_status(status)
    |> render(ErrorView, "error.json", message: message, code: status)
  end

  # defp changeset_error_msg(conn, status, message) do
  #   conn
  #   |> put_status(status)
  #   |> render(ErrorView, "changeset_error.json", message: message, code: status)
  # end

  defp validate_consultation_type(consultation_type) do
    consultation_type = String.downcase(consultation_type)
    if consultation_type != "initial" and consultation_type != "follow up" and consultation_type != "clearance" do
      {:error, "Invalid Consultation Type"}
    else
      {:valid}
    end
  end

  defp consult_params(params, practitioner_specialization) do
    practitioner_facility =
      PractitionerContext.get_practitioner_facility_by_practitioner_and_facility(
        practitioner_specialization.practitioner_id, params["facility_id"])
      params =
      Map.merge(params,
      %{"consultation_fee" => Decimal.to_string(practitioner_facility.consultation_fee)})
  end

  defp validate_origin(origin) do
    if Enum.member?(valid_origins(), origin) do
      {:valid}
    else
      {:error, "Invalid Origin"}
    end
  end

  defp valid_origins do
    [
      "accountlink",
      "doctorlink",
      "memberlink" ,
      "payorlink",
      "providerlink"
    ]
  end

  defp validate_required(params) do
    cond do
      is_nil(params["member_id"]) ->
        {:error, "Please enter a member"}
      is_nil(params["card_number"]) ->
        {:error, "Please enter card number"}
      is_nil(params["practitioner_specialization_id"]) ->
        {:error, "Please enter a practitioner specialization"}
      is_nil(params["facility_id"]) ->
        {:error, "Please enter a facility"}
      Enum.any?([is_nil(params["chief_complaint_others"]),
                 params["chief_complaint_others"] == ""]) ->
        {:error, "Please enter chief complaint"}
      true ->
        validate_required2(params)
    end
  end

  defp validate_required2(params) do
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

  defp check_practitioner_specialization(practitioner_specialization_id) do
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

  defp check_facility(facility_id) do
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

  defp check_diagnosis(diagnosis_id) do
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

  defp validate_card_number(card_number) do
    cond do
      Regex.match?(~r/^[0-9]*$/, card_number) == false ->
        {:error, "Card number should be numberic only"}
      String.length(card_number) != 16 ->
        {:error, "Card number should be 16-digits"}
      true ->
        {:ok, card_number}
    end
  end

  defp validate_member_card(member_id, card_number) do
    member = MemberContext.get_member_by_id_and_card_number(member_id, card_number)

    if not is_nil(member) do
      {:valid}
    else
      {:error, "Card number not affiliated with member"}
    end
  end

  defp validate_member(member_id) do
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

  defp validate_ps_consultation_fee(facility_id, ps_id) do
    ps = PractitionerContext.get_specialization_consultation_fee(facility_id, ps_id)
    if is_nil(ps) do
      {:error, "Practitioner Specialization has no consultation fee"}
    else
      {:ok}
    end
  end

end
