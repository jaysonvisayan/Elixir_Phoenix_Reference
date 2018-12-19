defmodule Innerpeace.PayorLink.Web.Api.V1.AuthorizationController do
  use Innerpeace.PayorLink.Web, :controller

  # alias Innerpeace.Db.Repo
  alias PayorLink.Guardian, as: PG
  alias Ecto.Changeset
  alias Ecto.DateTime
  alias Timex.Duration
  alias Innerpeace.Db.Parsers.{
    AcuScheduleParser,
    MemberParser
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
    BenefitContext
  }

  alias Innerpeace.Db.Base.Api.AuthorizationContext, as: AuthorizationAPI
  alias Innerpeace.Db.Base.Api.FacilityContext, as: FacilityContextAPI
  alias Innerpeace.Db.Base.Api.MemberContext, as: MemberContextAPI
  alias Innerpeace.Db.Validators.OPConsultValidator
  alias Innerpeace.Db.Validators.ACUValidator
  alias Innerpeace.Db.Validators.PEMEValidator
  alias Innerpeace.Db.Validators.OPLabValidator

  alias Innerpeace.Db.Schemas.{
    Authorization,
    Facility,
    Practitioner,
    Diagnosis,
    Member,
    Coverage,
    PractitionerSpecialization,
    Batch
  }

  alias Innerpeace.PayorLink.Web.Api.V1.AuthorizationView
  alias Innerpeace.PayorLink.Web.Api.V1.ErrorView

  def validate_coverage(conn, params) do
    with {:ok} <- AuthorizationAPI.validate_coverage_params(params),
         true <- is_acu?(params["coverage_name"]),
         {:ok, member} <- validate_coverage_member(params["card_no"]),
         {:ok, member_products} <- validate_coverage_member_product(AuthorizationAPI.get_member_product(member))
    do
        benefit_package =
          Enum.into(member_products, [], &(validate_benefit_package(member, &1)))
          |> List.flatten()
          |> List.delete(nil)
          |> Enum.count()

        conn
        |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "eligible.json", multiple: benefit_package > 1)
    else
      false ->
        conn
        |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "eligible.json")
      {:error, changeset} ->
        message = coverage_validation1(changeset, "ACU")
        message =
          if is_nil(message) do
            coverage_validation2(changeset)
          else
            message
          end
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: message)
      {:not_covered, message} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Member is not allowed to access this facility")
      {:not_covered} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Not covered")
    end
  end

  defp validate_coverage_member(nil), do: {:not_covered, "card_no is required"}
  defp validate_coverage_member(card_no), do: validate_coverage_member_v2(MemberContextAPI.get_member_by_card_number(card_no))
  defp validate_coverage_member_v2(nil), do: {:not_covered, "Member does not exist"}
  defp validate_coverage_member_v2(member), do: {:ok, member}

  defp validate_coverage_member_product([]), do: {:not_covered, "Member does not have any ACU plan"}
  defp validate_coverage_member_product(mp), do: {:ok, mp}

  defp is_acu?(nil), do: {:not_covered, "coverage_name is required"}
  defp is_acu?("ACU"), do: true
  defp is_acu?(_), do: false

  defp validate_benefit_package(member, nil), do: nil
  defp validate_benefit_package(member, mp) do
    Innerpeace.Db.Base.MemberContext.get_acu_package_based_on_member_for_schedule(
      member,
      mp
    )
  end

  def request_op_consult(conn, params) do
    user = PG.current_resource_api(conn)
    op_consult = CoverageContext.get_coverage_by_name("OP Consult")
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
      render(conn, Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "loa.json", loa: loa)
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

  def insert_utilization(conn, params) do
    with {:ok, changeset} <- AuthorizationAPI.utilization_validate_fields(params),
         member = %Member{} <- AuthorizationAPI.get_member_by_card_no(changeset.changes.member_card_no),
         facility = %Facility{} <- AuthorizationAPI.utilization_get_facility_by_code(changeset.changes.facility_code),
         %Coverage{} <- AuthorizationAPI.get_coverage_by_code!(changeset.changes.coverage_code),
         {:ok, admission_datetime} <- UtilityContext.transform_new_date(
           changeset.changes.admission_datetime),
         {:ok, admission_datetime} <- UtilityContext.transform_datetime(admission_datetime),
         {:ok, discharge_datetime} <- transform_discharge_date(changeset)
    do
      changeset = Changeset.put_change(changeset, :member_id, member.id)
      changeset = Changeset.put_change(changeset, :facility_id, facility.id)
      changeset = Changeset.put_change(changeset, :admission_datetime, admission_datetime)
      if is_nil(discharge_datetime) do
        changeset = Changeset.put_change(changeset, :discharge_datetime, admission_datetime)
      else
        {:ok, discharge_datetime} = UtilityContext.transform_datetime(discharge_datetime)
        changeset = Changeset.put_change(changeset, :discharge_datetime, discharge_datetime)
      end
      date = DateTime.to_date(changeset.changes.admission_datetime)
      valid_until = Timex.add(date, Duration.from_days(2))
      changeset = Changeset.put_change(changeset, :valid_until, valid_until)
      changeset = Changeset.put_change(changeset, :created_by_id, PG.current_resource_api(conn).id)
      changeset = Changeset.put_change(changeset, :updated_by_id, PG.current_resource_api(conn).id)
      coverage = AuthorizationAPI.get_coverage_by_code!(changeset.changes.coverage_code)
      changeset = Changeset.put_change(changeset, :coverage_id, coverage.id)
      changeset = Changeset.put_change(changeset, :step, 4)
      {:ok, authorization} = AuthorizationAPI.insert_authorization(changeset.changes)
      changeset = Changeset.put_change(changeset, :authorization_id, authorization.id)
      authorization_amount = AuthorizationAPI.insert_authorization_amount(changeset.changes)
      authorization_amount = AuthorizationAPI.insert_authorization_diagnosis(params["icd"],
      authorization.id, changeset.changes.member_id, PG.current_resource_api(conn).id)
      loa = AuthorizationContext.get_authorization_by_id(authorization.id)
      render(conn, Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "loa.json", loa: loa)
    else
      {:nil, "provider"} ->
        error_msg(conn, 400, "Facility Not Found")
      {:nil, "member"} ->
        error_msg(conn, 400, "Member Not Found")
      {:invalid_datetime_format} ->
        error_msg(conn, 400, "Invalid Admission DateTime Format")
      {:invalid_discharge_datetime} ->
        error_msg(conn, 400, "Invalid Discharge DateTime Format")
      nil ->
        error_msg(conn, 400, "Coverage Not Found")
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "changeset_error.json", changeset: changeset)
    end
  end

  defp transform_discharge_date(changeset) do
    if Map.has_key?(changeset.changes, :discharge_datetime) do
      with {:ok, discharge_datetime} <- UtilityContext.transform_new_date(
        changeset.changes.discharge_datetime)
      do
        {:ok, discharge_datetime}
      else
        _ ->
          {:invalid_discharge_datetime}
      end
    else
      {:ok, nil}
    end
  end

  defp validate_consultation_type(consultation_type) do
    consultation_type = String.downcase(consultation_type)
    if consultation_type != "initial" and consultation_type != "follow up" and consultation_type != "clearance" do
      {:error, "Invalid Consultation Type"}
    else
      {:valid}
    end
  end

  defp error_msg(conn, status, message) do
    conn
    |> put_status(status)
    |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "error.json", message: message, code: status)
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

  def request_acu(conn, params) do
    user = PG.current_resource_api(conn)
    authorization_id = params["authorization_id"]
    origin = params["origin"]
    card_no = params["card_no"]
    facility_code = params["facility_code"]
    coverage_code = params["coverage_code"]
    admission_date = params["admission_date"]
    discharge_date = params["discharge_date"]
    date_created = Date.utc_today()
    valid_until = Date.to_string(Date.add(date_created, 2))

    member = MemberContext.get_member_by_card_no(card_no)
    member = MemberContext.get_a_member!(member.id)
    facility = FacilityContext.get_facility_by_code(facility_code)
    coverage = CoverageContext.get_coverage_by_code(coverage_code)

    member_products =
      for member_product <- member.products do
        member_product
      end

    member_products =
      member_products
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten()

    # member_product =
    #   AuthorizationContext.get_member_product_with_coverage_and_tier(
    #     member_products,
    #     coverage.id
    #   )

    # benefit = product_benefit.benefit
    # benefit_package = List.first(benefit.benefit_packages)
    # package = benefit_package.package

    # benefit_packages =
    #   for member_product <- member_products do
    #     MemberContext.get_acu_package_based_on_member_for_schedule(member,
    #       member_product)
    #   end

    #   benefit_packages = AuthorizationAPI.get_multiple_package_acu(member, facility, benefit_packages, coverage)

    benefit_package = BenefitContext.get_benefit_package(params["benefit_package_id"])

    member_product = AuthorizationAPI.get_member_product_with_coverage_and_tier_with_package(member_products, facility, benefit_package, coverage)

    product_benefit =
      AuthorizationAPI.get_product_benefit_by_member_product_and_benefit_package(member_product, facility, benefit_package, coverage)

    product = member_product.account_product.product

    benefit = benefit_package.benefit


    authorization = AuthorizationContext.get_authorization_by_id(
      authorization_id
    )

    acu_params = %{
      authorization_id: authorization.id,
      user_id: get_user_id(user),
      member_id: authorization.member_id,
      facility_id: authorization.facility_id,
      coverage_id: authorization.coverage_id,
      room_id: "",
      benefit_package_id: benefit_package.id,
      admission_date: admission_date,
      discharge_date: discharge_date,
      product_id: product.id,
      product: product,
      internal_remarks: authorization.internal_remarks,
      valid_until: valid_until,
      member_product_id: member_product.id,
      product_benefit_id: product_benefit.id,
      origin: origin,
      product_benefit: product_benefit,
      package_id: benefit_package.package_id
    }

    with true <- AuthorizationAPI.validate_multiple_package_acu(member, facility, [benefit_package], coverage),
         {:ok, changeset} <- ACUValidator.request_acu(acu_params) do
      authorization =
        AuthorizationContext.get_authorization_by_id(
          changeset.changes.authorization_id
        )
      conn
      |> put_status(200)
      |> render(AuthorizationView, "acu_loa.json", loa: authorization)
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(400)
        |> render(ErrorView, "changeset_error.json", changeset: changeset)
      {:invalid_coverage, error} ->
        error_msg(conn, 400, error)
    end
  end

  defp get_user_id(nil), do: nil
  defp get_user_id(user), do: user.id

  def verify_acu(conn, params) do
    user = PG.current_resource_api(conn)
    authorization_id = params["authorization_id"]
    origin = params["origin"]
    facility_code = params["facility_code"]
    coverage_code = params["coverage_code"]
    admission_date = params["admission_date"]
    discharge_date = params["discharge_date"]
    date_created = Date.utc_today()
    valid_until = Date.to_string(Date.add(date_created, 2))

    member = if Map.has_key?(params, "member_id") do
      MemberContext.get_a_member!(params["member_id"])
    else
      card_no = params["card_no"]
      MemberContext.get_member_by_card_no(card_no)
    end

    facility = FacilityContext.get_facility_by_code(facility_code)
    coverage = CoverageContext.get_coverage_by_code(coverage_code)

    member_products =
      for member_product <- member.products do
        member_product
      end

    member_products =
      member_products
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten()

    member_product =
      AuthorizationContext.get_member_product_with_coverage_and_tier_clinic(
        member_products,
        coverage.id
      )

    product = if is_nil(member_product) do
      nil
    else
      member_product.account_product.product
    end

    product_id = if is_nil(product) do
      nil
    else
      product.id
    end

    product_benefit =
    MemberContext.get_acu_package_based_on_member(
      member,
      member_product
    )

    if is_nil(product_benefit) do
      product_benefit_id = nil
      benefit_package_id = nil
      member_product_id = nil
    else
      product_benefit_id = product_benefit.id
      benefit = product_benefit.benefit
      benefit_package = List.first(benefit.benefit_packages)
      benefit_package_id = benefit_package.id
      package = benefit_package.package
      member_product_id = member_product.id
    end

    authorization = AuthorizationContext.get_authorization_by_id(
      authorization_id
    )

    if is_nil(authorization) do
      error_msg(conn, 400, "Error in updating data in Payorlink")
    else
      acu_params = %{
        authorization_id: authorization.id,
        user_id: user.id,
        member_id: authorization.member_id,
        facility_id: authorization.facility_id,
        coverage_id: authorization.coverage_id,
        room_id: "",
        benefit_package_id: benefit_package_id,
        admission_date: admission_date,
        discharge_date: discharge_date,
        product_id: product_id,
        internal_remarks: authorization.internal_remarks,
        valid_until: valid_until,
        member_product_id: member_product_id,
        product_benefit_id: product_benefit_id,
        origin: origin,
        status: "Verified"
      }

      with {:ok, authorization} <- AuthorizationContext.verify_acu(authorization,
                                                                   acu_params,
                                                                   user.id)
      do
        authorization =
          AuthorizationContext.get_authorization_by_id(
            authorization.id
          )
        conn
        |> put_status(200)
        |> render(AuthorizationView, "acu_loa.json", loa: authorization)
      else
        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_status(400)
          |> render(ErrorView, "changeset_error.json", changeset: changeset)
        {:error} ->
          error_msg(conn, 400, "Error in updating data in Payorlink")
      end
    end
  end

  def coverage_validation1(changeset, coverage) do
    if coverage == "ACU" do
      {cn_message, _validation} = get_in(changeset.errors, [:card_no]) || {nil, []}
      message =
      cond do
      Map.has_key?(changeset.changes, :card_no) == false ->
        "Please enter card number"
      Map.has_key?(changeset.changes, :facility_code) == false ->
        "Please select a facility"
      Map.has_key?(changeset.changes, :coverage_name) == false ->
        "Please select a coverage"
      cn_message == "card number is not existing" ->
        "Card number does not exist"
      cn_message == "Member status must be Active to avail ACU." ->
        "Member status must be Active to avail ACU."
      cn_message == "Member status must be Active to avail LOA." ->
        "Member status must be Active to avail LOA."
      true ->
        nil
      end
    else
      {cn_message, _validation} = get_in(changeset.errors, [:member_id]) || {nil, []}
      message =
      cond do
      Map.has_key?(changeset.changes, :member_id) == false ->
        "Member does not exist"
      Map.has_key?(changeset.changes, :facility_code) == false ->
        "Please select a facility"
      Map.has_key?(changeset.changes, :coverage_name) == false ->
        "Please select a coverage"
      cn_message == "Member is not existing" ->
        "Member does not exist"
      true ->
        nil
      end
    end

  end

  def coverage_validation2(changeset) do
    {fc_message, _validation} = get_in(changeset.errors, [:facility_code]) || {nil, []}
    {cn_message, _validation} = get_in(changeset.errors, [:coverage_name]) || {nil, []}
    message =
    cond do
      fc_message == "facility is not affiliated" ->
        "Facility is not affiliated"
      fc_message == "facility code is not existing" ->
        "Facility code not found."
      cn_message == "No package facility rate setup." ->
        "No package facility rate setup."
      cn_message == "No facility room rate setup." ->
        "No facility room rate setup."
      true ->
        coverage_validation3(changeset)
    end
  end

  def coverage_validation3(changeset) do
    {fc_message, _validation} = get_in(changeset.errors, [:facility_code]) || {nil, []}
    {cn_message, _validation} = get_in(changeset.errors, [:coverage_name]) || {nil, []}
    message =
    cond do
      cn_message == "coverage name is not included in member product/s" ->
        case changeset.changes.coverage_name do
          "ACU" ->
            "Member is not eligible to avail any ACU package."
          "PEME" ->
            "Member is no longer valid to request PEME. Reason: Member has no benefit."
          "OP Consult" ->
            "Member is not allowed to avail Consultation. Reason: Member has no benefit."
        end
      cn_message == "coverage name is not existing" ->
        "Coverage name does not exist"
      cn_message == "Member has already an existing ACU Authorization record." ->
        "Member has already an existing ACU Authorization record."
      true ->
        cn_message
    end

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

  defp check_consultation_fee_and_affiliation_date(facility_id, practitioner_id) do
    practitioner_facility =
      PractitionerContext.get_pf_affiliation(practitioner_id, facility_id)
    if not is_nil(practitioner_facility) do
      date_today = Ecto.Date.utc
      af = Ecto.Date.compare(practitioner_facility.affiliation_date, date_today)
      daf = Ecto.Date.compare(practitioner_facility.disaffiliation_date, date_today)
      if not Enum.empty?(practitioner_facility.practitioner_facility_consultation_fees)
        and (af == :lt or af == :eq) and daf == :gt do
        {:validate_fee}
      else
        {:error, "Practitioner not affiliated with facility"}
      end
    else
      {:error, "Practitioner not affiliated with facility"}
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

  defp check_acu_member(card_no) do
    with member = %Member{} <- MemberContext.get_member_by_card_no(card_no),
         member = %Member{} <- MemberContext.get_a_member!(member.id)
    do
      {:ok, member}
    else
      _ ->
        {:invalid, "Invalid Member Card Number. Member does not exist!"}
    end
  end

  defp check_acu_facility(facility_code) do
    if not is_nil(facility_code) do
      with facility = %Facility{} <- FacilityContext.get_facility_by_code(facility_code) do
          {:ok, facility}
      else
        _ ->
          {:invalid, "Invalid Facility. Facility Code does not exist!"}
      end
    else
      {:invalid, "Invalid Facility. Facility Code is required!"}
    end
  end

  defp check_acu_coverage(coverage_code) do
    with true <- not is_nil(coverage_code),
         coverage = %Coverage{} <- CoverageContext.get_coverage_by_code(coverage_code) do
           {:ok, coverage}
    else
      _ ->
        {:invalid, "Invalid Coverage. Coverage Code does not exist!"}
         end
  end

  def get_acu_details_v2(conn, params) do
    user = PG.current_resource_api(conn)
    origin = params["origin"]
    requested_by = params["requested_by"]

    with {:ok, member} <- check_acu_member(params["card_no"]),
         {:ok, facility} <- check_acu_facility(params["facility_code"]),
         {:ok, coverage} <- check_acu_coverage(params["coverage_code"])
    do
      filtered_available_mp =
        member.products
        |> Enum.map(&(&1.account_product.product.product_benefits
        |> Enum.map(fn(a) -> a.benefit.benefit_coverages
        |> Enum.into([], fn(b) -> if b.coverage.id == coverage.id, do: &1, else: nil end) end)))
        |> List.flatten() |> Enum.uniq |> List.delete(nil)
        |> AuthorizationContext.packages_based_on_age_and_gender(member, facility)

      with  false <- Enum.empty?(filtered_available_mp) do
        authorization_params =
          %{
            "member_id" => member.id,
            "facility_id" => facility.id,
            "coverage_id" => coverage.id,
            "step" => 3,
            "created_by_id" => user.id,
            "origin" => origin,
            "number" => AuthorizationContext.random_loa_number(),
            "requested_by" => requested_by
          }
        case AuthorizationContext.create_authorization_api(user.id, authorization_params) do
          {:ok, authorization} ->
            filtered_available_mp =
              filtered_available_mp |> Enum.map(&(&1) |> Map.put(:authorization_id, authorization.id))
            conn
            |> put_status(200)
            |> render(AuthorizationView, "acu_details2.json", filtered_available_mp: filtered_available_mp, authorization: authorization)
          {:error, changeset} ->
            conn
            |> put_status(400)
            |> render(ErrorView, "changeset_error.json", changeset: changeset)
        end
      else
        true -> # []
          conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "error.json", message: "Member is not Eligible to any of the Products")
        {:member_already_availed, message} ->
          conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "error.json", message: message)
      end

    else
    {:invalid, message} ->
    error_msg(conn, 400, message)
    _ ->
    error_msg(conn, 400, "Invalid Parameters")
    end
  end

  def get_acu_details(conn, params) do
    user = PG.current_resource_api(conn)
    origin = params["origin"]
    card_no = params["card_no"]
    facility_code = params["facility_code"]
    coverage_code = params["coverage_code"]
    requested_by = params["requested_by"]

    with {:ok, member} <- check_acu_member(card_no),
         {:ok, facility} <- check_acu_facility(facility_code),
         {:ok, coverage} <- check_acu_coverage(coverage_code)
    do
      member_products =
        member.products
        |> Enum.into([], &(&1))

      coverage = CoverageContext.get_coverage_by_name("ACU")
      benefit_packages =
        member_products
        |> Enum.map(&(MemberContext.get_acu_package_based_on_member_for_schedule(member, &1)))

      with true <- AuthorizationAPI.validate_multiple_package_acu(member, facility, benefit_packages, coverage)
      do
        benefit_packages = AuthorizationAPI.get_multiple_package_acu(member, facility, benefit_packages, coverage)

        authorization_params = %{
          "member_id" => member.id,
          "facility_id" => facility.id,
          "coverage_id" => coverage.id,
          "step" => 3,
          "created_by_id" => user.id,
          "origin" => origin,
          "requested_by" => requested_by
        }

        with {:ok, authorization} <-
          AuthorizationContext.create_authorization_api(
            user.id,
            authorization_params
          )
        do
          conn =
            conn
            |> put_status(200)
            |> render(AuthorizationView, "acu_details.json", member: member,
                      authorization: authorization, benefit_packages: benefit_packages, facility: facility)
        else
          {:error, changeset} ->
            conn
            |> put_status(400)
            |> render(ErrorView, "changeset_error.json", changeset: changeset)
        end
      else
        {:old_data} ->
          error_msg(conn, 400, "Product is old data, try to create new product.")
        {:invalid_coverage, error} ->
          error_msg(conn, 400, error)
      end
    else
      {:invalid, message} ->
        error_msg(conn, 400, message)
      _ ->
        error_msg(conn, 400, "Invalid Parameters")
    end
  end

  defp check_benefit_package(benefit_package) do
    benefit_package = List.first(benefit_package)
    if is_nil(benefit_package) do
      {:old_data}
    else
      {:valid, benefit_package}
    end
  end

  def insert_acu_details(user, params) do
    origin = params["origin"]
    card_no = params["card_no"]
    facility_code = params["facility_code"]
    coverage_code = params["coverage_code"]

    member = MemberContext.get_member_by_card_no(card_no)
    member = MemberContext.get_a_member!(member.id)
    facility = FacilityContext.get_facility_by_code(facility_code)

    with coverage = %Coverage{} <- CoverageContext.get_coverage_by_code(coverage_code) do

      member_products =
        for member_product <- member.products do
          member_product
        end

      member_products =
        member_products
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.flatten()

      member_product =
        AuthorizationContext.get_member_product_with_coverage_and_tier(
          member_products,
          coverage.id
        )

      product = member_product.account_product.product

      product_benefit =
        MemberContext.get_acu_package_based_on_member(
          member,
          member_product
        )
      pbl = ProductContext.get_product_benefit(product_benefit.id).product_benefit_limits

      limit_amount = if Enum.empty?(pbl) do
        limit_amount = Decimal.new(0)
      else

        product_benefit_limit =
          pbl
          |> List.first()

        limit_amount = product_benefit_limit.limit_amount || Decimal.new(0)
      end

      benefit = product_benefit.benefit
      benefit_package =
        MemberContext.get_acu_package_based_on_member_for_schedule(
          member,
          member_product
        )

      benefit_package = benefit_package
                        |> List.first()

      package = benefit_package.package
      payor_procedures = AuthorizationView.payor_procedures(package, member)

      with true <- AuthorizationAPI.validate_acu(member, coverage),
           true <- AuthorizationAPI.validate_acu_pf_schedule(facility.id, member.id, coverage, product_benefit)
      do
        package_facility_rate =
          AuthorizationView.package_facility_rate(
            package.package_facility,
            facility.id
          )

        package =
          package
          |> Map.merge(%{package_facility_rate: package_facility_rate})

        benefit =
          benefit
          |> Map.merge(%{limit_amount: limit_amount})

        authorization_params = %{
          "member_id" => member.id,
          "facility_id" => facility.id,
          "coverage_id" => coverage.id,
          "step" => 3,
          "created_by_id" => user.id,
          "origin" => origin
        }

        with {:ok, authorization} <-
          AuthorizationContext.create_authorization_api(
            user.id,
            authorization_params
          )
        do
          {authorization, benefit, benefit_package, package, payor_procedures, product}
        else
          _ ->
            {:error_inserting_acu}
        end
      else
        false ->
          {:error, "Failed in loa first validation"}
        {:invalid_coverage, "Member is not eligible to avail ACU in this Hospital / Clinic."} ->
          {:error, "Member is not eligible to avail ACU in this Hospital / Clinic."}
        {:invalid_coverage, "Member is not eligible to avail ACU. Reason: Member's ACU package is not available in this facility."} ->
          {:error, "Member's ACU package is not available in this facility."}
        _ ->
          {:error, "Error in ACU setup"}
      end
    else
      _ ->
        {:error, "No coverage"}
    end
  end

  def cancel_authorization(conn, %{"id" => id}) do
    with {:ok, loa} <- AuthorizationContext.cancel_authorization(id) do
      authorization = AuthorizationContext.get_authorization_by_id(loa.id)
      MemberContext.update_member_products_by_package_id(
        loa.member_id,
        Enum.at(loa.authorization_benefit_packages, 0).benefit_package.package_id,
        false
      )
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "success")
    else
      {:missing} ->
        conn
        |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "loa not found")
      {:invalid, message} ->
        conn
        |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: message)
      _ ->
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "failed")
    end
  end

  def cancel_authorization(conn, _params) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "error.json", message: "Not Found")
  end

  def update_loa_number(conn, params) do
    with false <- is_nil(params["loa_no"])  or params["loa_no"] == "",
         {:ok, authorization} <- AuthorizationAPI.update_loa_number(params) do
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "success")
    else
      true ->
       conn
       |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "Invalid parameters")
      _ ->
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "loa not found")
    end
  end

  def update_loa_number(conn, _params) do
    conn
    |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "Invalid parameters")
  end

  def update_otp_status(conn, params) do
    loa_id = params["authorization_id"]
    with {:ok, authorization} <- AuthorizationAPI.update_otp_status(loa_id) do
      AuthorizationAPI.create_claim(params["authorization_id"], params["batch_no"])
      AuthorizationAPI.create_claim_in_providerlink(params["batch_no"], authorization.number)
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "success")
    else
      true ->
       conn
       |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "Invalid parameters")
      _ ->
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "loa not found")
    end
  end

  def update_peme_status(conn, params) do
    if params["availment_date"] == "" or is_nil(params["availment_date"]) do
      conn
      |> put_status(400)
      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "Invalid parameters")
    else
      if UtilityContext.validate_yyyymmdd_format(params["availment_date"]) do
        params  =
          params
          |> Map.put("availment_date", Ecto.Date.cast!(params["availment_date"]))
        loa_id = params["authorization_id"]
        with {:ok, authorization} <- AuthorizationAPI.update_peme_status(loa_id, params) do
          conn
          |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "claims3.json", claims: authorization)
          # conn
          # |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "success")
        else
          true ->
          conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "Invalid parameters")
          _ ->
          conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "loa not found")
        end
      else
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "Invalid Availment Date Format")
      end
    end
  end

  def update_batch_otp_status(conn, params) do
    user = PG.current_resource_api(conn)
    verified_ids = params["verified_ids"]
    forfeited_ids = params["forfeited_ids"]

    with {:ok, verified_ids} <- is_list_verified(is_list(params["verified_ids"]), params["verified_ids"]),
         {:ok, forfeited_ids} <- is_list_forfeited(is_list(params["forfeited_ids"]), params["forfeited_ids"]),
         {:ok, batch} <- create_batch_acu_schedule_loa(verified_ids, user, params),
         {:ok, acu_schedule} <- AcuScheduleContext.update_acu_schedule_batch_id(params["acu_schedule_batch_no"], batch.id)
    do
      verified_ids = Enum.map(verified_ids, fn(x) ->
        create_batch_authorization(x, batch.id, user)
        %{
          authorization_id: x,
          batch_no: batch.batch_no
        }
      end)

      AcuScheduleParser.upload_a_file_batch(batch.id, params["file"], user)

      if params["photo_file"]["base_64_encoded"] != "" do
       member_photo(params["member_id"], params["photo_file"], user)
      end

      update_verified(verified_ids)

      update_forfeited(forfeited_ids)

      with {:ok, batch_no} <- claim_checker(batch.batch_no, AuthorizationAPI.get_claim_count_batch_no(batch.batch_no), Enum.count(verified_ids)),
           {:ok, response} <- AuthorizationAPI.create_claim_in_providerlink(batch_no, "")
      do
        render(conn, Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "success")
      else
        _ ->
          error_msg(conn, 400, "failed")
      end
    else
      {:invalid, message} ->
        error_msg(conn, 400, message)
      _ ->
        error_msg(conn, 400, "failed")
    end
  end

  defp is_list_verified(true, list), do: {:ok, list}
  defp is_list_verified(false, nil), do: {:invalid, "verified_ids is required"}
  defp is_list_verified(false, _), do: {:invalid, "verified_ids must be an array"}

  defp is_list_forfeited(true, list), do: {:ok, list}
  defp is_list_forfeited(false, nil), do: {:invalid, "forfeited_ids is required"}
  defp is_list_forfeited(false, _), do: {:invalid, "forfeited_ids must be an array"}

  def create_batch_for_acu_schedule(conn, params) do
    user = PG.current_resource_api(conn)
    date_due = Date.add(Date.utc_today(), 1)
    {:ok, date_received} = Ecto.Date.cast(Date.utc_today() |> Date.to_erl)
    {:ok, date_due} = Ecto.Date.cast(date_due |> Date.to_erl)
    batch_params =
      %{
        "batch_no" => params["batch_no"],
        "type" => params["type"],
        "date_received" => date_received,
        "date_due" => date_due,
        "facility_id" => params["facility_id"],
        "coverage" => coverage_val(params["coverage"]),
        "soa_ref_no" => soa_ref_no_val(params["soa_ref_no"]),
        "soa_amount" => soa_amount_val(params["soa_amount"]),
        "edited_soa_amount" => edited_soa_amount_val(params["edited_soa_amount"]),
        "estimate_no_of_claims" => params["registered"],
        "mode_of_receiving" => "Sample 1",
        "status" => "Submitted"
      }
    {:ok, batch} = BatchContext.create_hb_batch(batch_params, user.id, params["batch_no"])
    AcuScheduleContext.update_acu_schedule_batch_id(params["acu_schedule_batch_no"], batch.id)
    render(conn, Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "success")
  end

  def create_batch_for_clinic(conn, params) do
    with %Facility{} <- FacilityContext.get_facility(params["facility_id"]) do
      user = PG.current_resource_api(conn)
      date_due = Date.add(Date.utc_today(), 1)
      {:ok, date_received} = Ecto.Date.cast(Date.utc_today() |> Date.to_erl)
      {:ok, date_due} = Ecto.Date.cast(date_due |> Date.to_erl)
      batch_params =
        %{
          "batch_no" => params["batch_no"],
          "type" => params["type"],
          "date_received" => date_received,
          "date_due" => date_due,
          "facility_id" => params["facility_id"],
          "coverage" => coverage_val(params["coverage"]),
          "soa_ref_no" => soa_ref_no_val(params["soa_ref_no"]),
          "soa_amount" => soa_amount_val(params["soa_amount"]),
          "edited_soa_amount" => edited_soa_amount_val(params["edited_soa_amount"]),
          "estimate_no_of_claims" => "1",
          "mode_of_receiving" => "Sample 1",
          "status" => "Submitted"
        }
      {:ok, batch} = BatchContext.create_hb_batch(batch_params, user.id, params["batch_no"])

      create_batch_authorization(params["authorization_id"], batch.id, user)
      AuthorizationAPI.update_otp_status(params["authorization_id"])
      AuthorizationAPI.create_claim(params["authorization_id"], params["batch_no"])
      AuthorizationAPI.create_claim_in_providerlink(params["batch_no"], "")
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "success")
    else
      _ ->
        error_msg(conn, 400, "Facility not found!")
    end
  end

  def update_otp_status_v2(conn, params) do
    user = PG.current_resource_api(conn)
    verified_ids = params["verified_ids"]
    forfeited_ids = params["forfeited_ids"]
    with batch = %Batch{} <- BatchContext.get_batch_no(params["batch_no"]) do
      BatchContext.update_batch_amounts(batch, params)
      update_otp_status_with_batch(conn, user, verified_ids, params, batch)
    else
      _ ->
        error_msg(conn, 400, "Batch number not found!")
    end
  end

  defp update_otp_status_without_batch(conn, user, verified_ids, params) do
    with {:ok, batch} <- create_batch_acu_schedule_loa(verified_ids, user, params) do
      verified_ids = Enum.map(verified_ids, fn(x) ->
        create_batch_authorization(x, batch.id, user)
        %{
          authorization_id: x,
          batch_no: batch.batch_no
        }
      end)

      # AcuScheduleParser.upload_a_file_batch(batch.id, params["file"], user)

      if params["photo_file"]["base_64_encoded"] != "" do
       member_photo(params["member_id"], params["photo_file"], user)
      end

      update_verified(verified_ids)

      with {:ok, batch_no} <- claim_checker(batch.batch_no, AuthorizationAPI.get_claim_count_batch_no(batch.batch_no), Enum.count(verified_ids)),
           {:ok, response} <- AuthorizationAPI.create_claim_in_providerlink(batch_no, "")
      do
        render(conn, Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "success")
      else
        _ ->
          render(conn, Innerpeace.PayorLink.Web.Api.V1.ErrorView, "error.json", message: "failed", code: 400)
      end
    else
      _ ->
        render(conn, Innerpeace.PayorLink.Web.Api.V1.ErrorView, "error.json", message: "failed", code: 400)
    end
  end

  defp update_otp_status_with_batch(conn, user, verified_ids, params, batch) do
    verified_ids = get_verified_ids(verified_ids, batch, user)
    if params["photo_file"]["base_64_encoded"] != "" do
      member_photo(params["member_id"], params["photo_file"], user)
    end

    with {:ok} <- AcuScheduleParser.upload_a_file_batch(batch.id, params["file"], user),
         {:ok, _} <- update_verified(verified_ids),
         {:ok, batch_no} <- claim_checker(batch.batch_no, AuthorizationAPI.get_claim_count_batch_no(batch.batch_no), Enum.count(verified_ids)),
         {:ok, response} <- AuthorizationAPI.create_claim_in_providerlink(batch_no, "")
    do
      render(conn, Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "success")
    else
      {:unable_to_login} ->
        error_msg(conn, 400, "Unable to login to ProviderLink API")
      {:error_connecting_api} ->
        error_msg(conn, 400, "Error connecting to ProviderLink API")
      {:invalid, message} ->
        error_msg(conn, 400, message)
      _ ->
        error_msg(conn, 400, "failed")
    end
  rescue
    Ecto.ConstraintError ->
      error_msg(conn, 400, "Already updated otp status")
  end

  defp get_verified_ids(verified_ids, batch, user) do
    verified_ids
    |> Enum.map(fn(id) ->
      create_batch_authorization(id, batch.id, user)
      %{
        authorization_id: id,
        batch_no: batch.batch_no
      }
    end)
  end

  defp claim_checker(batch_no, remaining_claims, total_claims) do
    if AuthorizationAPI.get_claim_count_batch_no(batch_no) != total_claims do
      remaining_claims = AuthorizationAPI.get_claim_count_batch_no(batch_no)
      claim_checker(batch_no, remaining_claims, total_claims)
    else
      {:ok, batch_no}
    end
  end

  defp member_photo(nil, nil, user), do: nil
  defp member_photo(member_id, nil, user), do: nil
  defp member_photo(nil, photo_file, user), do: nil
  defp member_photo(member_id, photo_file, user) do
    MemberParser.upload_a_photo(member_id, photo_file, user)
  end

  defp update_verified([]), do: nil
  defp update_verified(nil), do: nil
  defp update_verified(verified_ids) do
    # Enum.into(verified_ids, [], &(AuthorizationAPI.update_verified(&1)))
    AuthorizationAPI.update_availed_job(verified_ids)
  end

  defp update_forfeited([]), do: nil
  defp update_forfeited(nil), do: nil
  defp update_forfeited(forfeited_ids) do
    # Enum.into(forfeited_ids, [], &(AuthorizationAPI.update_forfeited(&1)))
    AuthorizationAPI.update_forfeited_job(forfeited_ids)
  end

  defp create_batch_acu_schedule_loa(verified_ids, user, params) do
    batch_no = params["batch_no"]
    coverage = params["coverage"]
    soa_ref_no = params["soa_ref_no"]
    soa_amount = params["soa_amount"]
    computed_soa_amount = params["edited_soa_amount"]
    type = params["type"]

    if !Enum.empty?(verified_ids) do
      authorization = AuthorizationContext.get_authorization_by_id(List.first(verified_ids))
      if !is_nil(authorization) do
        date_due = Date.add(Date.utc_today(), 1)
        {:ok, date_received} = Ecto.Date.cast(Date.utc_today() |> Date.to_erl)
        {:ok, date_due} = Ecto.Date.cast(date_due |> Date.to_erl)
        batch_params =
          %{
            "batch_no" => batch_no,
            "type" => type,
            "date_received" => date_received,
            "date_due" => date_due,
            "facility_id" => authorization.facility_id,
            "coverage" => coverage_val(coverage),
            "soa_ref_no" => soa_ref_no_val(params["soa_ref_no"]),
            "soa_amount" => soa_amount_val(params["soa_amount"]),
            "edited_soa_amount" => edited_soa_amount_val(params["edited_soa_amount"]),
            "estimate_no_of_claims" => "#{Enum.count(verified_ids)}",
            "mode_of_receiving" => "Sample 1",
            "status" => "Submitted",
            "edited_soa_amount" => computed_soa_amount
          }
          BatchContext.create_hb_batch(batch_params, user.id, batch_no)
      end
    end
  end

  defp create_batch_authorization(authorization_id, batch_id, user) do
    batch_authorization_params =
      %{
        "authorization_id" => authorization_id,
        "batch_id" => batch_id
      }
    BatchContext.insert_batch_authorization(batch_authorization_params, user.id)
  end

  defp coverage_val(nil), do: "ACU"
  defp coverage_val(coverage), do: coverage

  defp soa_ref_no_val(nil), do: nil
  defp soa_ref_no_val(soa_ref_no), do: soa_ref_no

  defp soa_amount_val(nil), do: "0"
  defp soa_amount_val(soa_amount), do: soa_amount

  defp edited_soa_amount_val(nil), do: "0"
  defp edited_soa_amount_val(edited_soa_amount), do: edited_soa_amount

  #PEME
  def request_peme(conn, params) do
    result = if is_nil(Guardian.Plug.current_resource(conn)) do
      user = PG.current_resource_api(conn)
      %{user: user, accountlink_web: false}
    else
      user = Guardian.Plug.current_resource(conn)
      %{user: user, accountlink_web: true}
    end

    user = result.user

    accountlink_web = result.accountlink_web
    authorization_id = params["authorization_id"]
    origin = params["origin"]
    facility_code = params["facility_code"]
    coverage_code = params["coverage_code"]
    admission_date = params["admission_date"]
    date_created = Date.utc_today()
    valid_until = Date.to_string(Date.add(date_created, 2))

    if Map.has_key?(params, "member_id") do
      member = MemberContext.get_a_member!(params["member_id"])
    else
      card_no = params["card_no"]
      member = MemberContext.get_member_by_card_no(card_no)
      member = MemberContext.get_a_member!(member.id)
    end

    facility = FacilityContext.get_facility_by_code(facility_code)
    coverage = CoverageContext.get_coverage_by_code(coverage_code)

    member_products =
    AuthorizationContext.get_member_product_with_coverage_and_tier2(
      member.products,
      coverage.id
    )

    peme = MemberContext.get_peme_by_member_id(member.id)

    benefit_packages =
      MemberContext.get_peme_package_based_on_member_for_schedule2(
        member,
        member_products
      )

    benefit_packages2 = Enum.map(benefit_packages, fn(benefit_package) ->
      Enum.map(benefit_package, fn(x) ->
        if x.package.id == peme.package.id do
          x
        else
          nil
        end
      end)
    end)

    benefit_packages2 =
      benefit_packages2
      |> Enum.uniq()
      |> List.flatten()
      |> List.delete(nil)
      |> List.first()

    benefit = BenefitContext.get_benefit(benefit_packages2.benefit_id)
    package = benefit_packages2.package
    payor_procedures = AuthorizationView.payor_procedures(package, member)

    product_benefits =
    MemberContext.get_peme_product_benefit_based_on_member_for_schedule2(
      member,
      member_products
    )

    product_benefits2 = Enum.map(product_benefits, fn(product_benefit) ->
      Enum.find(product_benefit, &(&1.benefit.id == benefit.id))
    end)

    product_benefit =
        product_benefits2
        |> Enum.uniq()
        |> List.flatten()
        |> List.delete(nil)
        |> List.first()

    product = ProductContext.get_product!(product_benefit.product.id)

    member_products = Enum.map(member.products, fn(member_product) ->
      if member_product.account_product.product.id == product.id do
        member_product
      else
        nil
      end
    end)

    member_product =
      member_products
      |> Enum.uniq()
      |> List.flatten()
      |> List.delete(nil)
      |> List.first()

    authorization = AuthorizationContext.get_authorization_by_id(
      authorization_id
    )

    peme_params = %{
      authorization_id: authorization.id,
      user_id: user.id,
      member_id: authorization.member_id,
      facility_id: authorization.facility_id,
      coverage_id: authorization.coverage_id,
      room_id: "",
      benefit_package_id: benefit_packages2.id,
      admission_date: admission_date,
      product_id: product.id,
      internal_remarks: authorization.internal_remarks,
      valid_until: valid_until,
      member_product_id: member_product.id,
      product_benefit_id: product_benefit.id,
      origin: origin,
      product_benefit: product_benefit
    }

    with {:ok, changeset} <- PEMEValidator.request_peme(peme_params) do
      authorization =
        AuthorizationContext.get_authorization_by_id(
          changeset.changes.authorization_id
        )
        conn
        |> put_status(200)
        |> render(AuthorizationView, "acu_loa.json", loa: authorization)
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(400)
        |> render(ErrorView, "changeset_error.json", changeset: changeset)
      {:invalid_coverage, error} ->
        error_msg(conn, 400, error)
    end
  end

  def get_peme_details(conn, params) do
    result = if is_nil(Guardian.Plug.current_resource(conn)) do
      user = PG.current_resource_api(conn)
      %{user: user, accountlink_web: false}
    else
      user = Guardian.Plug.current_resource(conn)
      %{user: user, accountlink_web: true}
    end

    admission_datetime = params["admission_datetime"]
    discharge_datetime = params["discharge_datetime"]
    user = result.user
    accountlink_web = result.accountlink_web
    origin = params["origin"]
    facility_code = params["facility_code"]
    coverage_code = "PEME"
    date_created = Date.utc_today()
    valid_until = Date.to_string(Date.add(date_created, 2))
    member_id = if not is_nil(params["member_id"]) do
        params["member_id"]
    else
      ""
    end
    if Map.has_key?(params, "member_id") do
      member = MemberContext.get_a_member!(params["member_id"])
    else
      card_no = params["card_no"]
      if not is_nil(card_no) do
        member = MemberContext.get_member_by_card_no(card_no)
        member = MemberContext.get_a_member!(member.id)
      else
        member = nil
      end
    end

    if not is_nil(member) do
      facility = FacilityContext.get_facility_by_code(facility_code)
      coverage = CoverageContext.get_coverage_by_code(coverage_code)

      member_products =
        AuthorizationContext.get_member_product_with_coverage_and_tier2(
          member.products,
          coverage.id
        )

        member_product =
          member_products
          |> Enum.uniq()
          |> List.flatten()
          |> List.delete(nil)
          |> List.first()

        peme = MemberContext.get_peme_by_member_id(member.id)

        benefit_packages =
          MemberContext.get_peme_package_based_on_member_for_schedule2(
            member,
            member_products
          )

      benefit_packages2 = Enum.map(benefit_packages, fn(benefit_package) ->
        Enum.map(benefit_package, fn(x) ->
          if is_nil(x) do
            nil
          else
            if x.package.id == peme.package.id do
              x
            else
              nil
            end
          end
        end)
      end)

      benefit_packages2 =
        benefit_packages2
        |> Enum.uniq()
        |> List.flatten()
        |> List.delete(nil)
        |> List.first()

      benefit = BenefitContext.get_benefit(benefit_packages2.benefit_id)

      product_benefits =
        MemberContext.get_peme_product_benefit_based_on_member_for_schedule2(
          member,
          member_products
        )

      product_benefits2 = Enum.map(product_benefits, fn(product_benefit) ->
        Enum.find(product_benefit, &(&1.benefit.id == benefit.id))
      end)

      product_benefit =
        product_benefits2
        |> Enum.uniq()
        |> List.flatten()
        |> List.delete(nil)
        |> List.first()

      product = ProductContext.get_product!(product_benefit.product.id)
      package = benefit_packages2.package
      payor_procedures = AuthorizationView.payor_procedures(package, member)

      with true <- AuthorizationAPI.validate_peme_member(member, coverage, facility.id),
           true <- AuthorizationAPI.validate_peme(member, coverage),
           true <- AuthorizationAPI.validate_peme_existing(member, coverage, facility.id),
           true <- AuthorizationAPI.validate_peme_pf(facility.id, member.id, coverage)
      do

        package_facility_rate =
          AuthorizationView.package_facility_rate(
            package.package_facility,
            facility.id
          )

        package =
          package
          |> Map.merge(%{package_facility_rate: package_facility_rate})

        ap_status = if accountlink_web, do: "Approved", else: "Draft"

        authorization_params = %{
          "member_id" => member.id,
          "facility_id" => facility.id,
          "coverage_id" => coverage.id,
          "step" => 3,
          "created_by_id" => user.id,
          "origin" => origin,
          "is_peme?" => true,
          "status" => ap_status
        }
        with {:ok, authorization} <-
          AuthorizationContext.create_authorization_api(
            user.id,
            authorization_params
          )
        do
          if accountlink_web do
            peme
            |> MemberContext.update_peme_authorization(
              authorization.id
            )

            pm_param = %{
              admission_date: Ecto.Date.to_string(admission_datetime),
              discharge_date: Ecto.Date.to_string(discharge_datetime),
              authorization_id: authorization.id,
              benefit_package_id: benefit_packages2.id,
              benefit_code: benefit.code,
              package: [
                id: package.id,
                code: package.code,
                name: package.name
              ],
              member_id: member_id,
              room_id: "",
              package_facility_rate: package.package_facility_rate,
              payor_procedure: payor_procedures,
              product_benefit: product_benefit,
              product_benefit_id: product_benefit.id,
              valid_until: valid_until,
              member_product_id: member_product.id,
              origin: origin,
              internal_remarks: authorization.internal_remarks,
              product_id: product.id,
              facility_id: facility.id,
              coverage_id: coverage.id,
              user_id: user.id,
              member: member
            }
            {:ok, pm_param}
          else
            conn
            |> put_status(200)
            |> render(AuthorizationView, "peme_details.json", member: member,
                      benefit: benefit, benefit_package: benefit_packages2,
                      package: package, payor_procedures: payor_procedures,
                      authorization: authorization)
          end

        else
          {:error, changeset} ->
            if accountlink_web do
              {:error, changeset}
            else
              conn
              |> put_status(400)
              |> render(ErrorView, "changeset_error.json", changeset: changeset)
            end
        end

        else
        {:invalid_coverage, error} ->
          if accountlink_web do
            {:error, error}
          else
            error_msg(conn, 400, error)
          end
      end

      else
      if accountlink_web do
        {:error, "invalid_params"}
      else
        error_msg(conn, 400, "Invalid Parameters")
      end
    end
  end

  defp has_member_id(params, true), do: MemberContext.get_a_member!(params["member_id"])
  defp has_member_id(params, false), do: get_member_by_card(params["card_no"])

  defp get_member_by_card(nil), do: nil
  defp get_member_by_card(card_no), do: MemberContext.get_member_by_card_no(card_no)

  defp simplify_struct(struct) do
    struct
    |> Enum.uniq()
    |> List.flatten()
    |> List.delete(nil)
    |> List.first()
  end

  defp get_benefit_package(nil, peme), do: nil
  defp get_benefit_package(bp, peme) do
    get_package(bp, bp.package.id == peme.package.id)
  end

  defp get_package(bp, true), do: bp
  defp get_package(bp, false), do: nil

  defp check_if_api_or_web(conn, nil) do
    user = Guardian.Plug.current_resource(conn)
    %{user: user, accountlink_web: true}
  end

  defp check_if_api_or_web(conn, current_resource) do
    user = PG.current_resource_api(conn)
    %{user: user, accountlink_web: false}
  end

  def request_peme_v2(conn, params) do
    result = check_if_api_or_web(conn, Guardian.Plug.current_resource(conn))
    member = has_member_id(params, Map.has_key?(params, "member_id"))

    request_peme(conn, member, params, result)
  end

  def request_peme(conn, nil, params, result) do
    error_msg(conn, 400, "Invalid Parameters")
  end

  def request_peme(conn, member, params, result) do
    facility = FacilityContext.get_facility_by_code(params["facility_code"])
    coverage = CoverageContext.get_coverage_by_code("PEME")
    member_products =
      AuthorizationContext.get_member_product_with_coverage_and_tier2(
        member.products,
        coverage.id
      )
    member_product = simplify_struct(member_products)
    peme = MemberContext.get_peme_by_member_id(member.id)

    benefit_packages =
      MemberContext.get_peme_package_based_on_member_for_schedule2(
        member,
        member_products
      )

    benefit_packages2 =
      benefit_packages
      |> Enum.map(fn(benefit_package) ->
          Enum.map(benefit_package, fn(bp) -> get_benefit_package(bp, peme) end)
        end)
      |> simplify_struct()

    params = %{
      member: member,
      params: params,
      result: result,
      scheme: conn.scheme,
      member_products: member_products,
      member_product: member_product,
      peme: peme,
      coverage: coverage,
      facility: facility
    }

    validate_benefits(conn, benefit_packages2, params)
  end

  defp validate_benefits(conn, nil, params) do
    error_msg(conn, 400, "Invalid PEME Member Benefits")
  end

  defp validate_benefits(conn, benefit_packages2, params) do
    member = params.member
    coverage = params.coverage
    facility = params.facility

    benefit = BenefitContext.get_benefit(benefit_packages2.benefit_id)
    product_benefit = get_product_benefit(member, params, benefit)
    product = ProductContext.get_product!(product_benefit.product.id)
    package = benefit_packages2.package
    payor_procedures = AuthorizationView.payor_procedures(package, member) # Changed

    with true <- AuthorizationAPI.validate_peme_member(member, coverage, facility.id),
         true <- AuthorizationAPI.validate_peme(member, coverage),
         true <- AuthorizationAPI.validate_peme_existing(member, coverage, facility.id),
         true <- AuthorizationAPI.validate_peme_pf(facility.id, member.id, coverage)
    do
      params
      |> Map.put(:product, product)
      |> Map.put(:package, package)
      |> Map.put(:benefit, benefit)
      |> Map.put(:benefit_packages2, benefit_packages2)
      |> Map.put(:product_benefit, product_benefit)
      |> Map.put(:payor_procedures, payor_procedures)
      |> request_peme_payorlink(conn)
    else
      {:invalid_coverage, error} ->
        error_msg(conn, 400, error)
    end
  end

  defp get_product_benefit(member, params, benefit) do
    member
    |> MemberContext.get_peme_product_benefit_based_on_member_for_schedule2(params.member_products)
    |> Enum.map(fn(product_benefit) ->
        Enum.find(product_benefit, &(&1.benefit.id == benefit.id))
       end)
    |> simplify_struct()
  end

  defp request_peme_payorlink(params, conn) do
    package_facility_rate = # Changed
      AuthorizationView.package_facility_rate(
        params.package.package_facility,
        params.facility.id
      )
    package = Map.merge(params.package, %{package_facility_rate: package_facility_rate})
    authorization_params = authorization_params(params)

    with {:ok, authorization} <-
      AuthorizationContext.create_authorization_api(
        params.result.user.id,
        authorization_params
      )
    do
      pm_param = peme_params(authorization, params, package_facility_rate)
      request_peme_to_providerlink(conn, authorization, params.params["evoucher"], params.member, pm_param)
    else
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(ErrorView, "changeset_error.json", changeset: changeset)
    end
  end

  defp authorization_params(params) do
    ap_status = if params.result.accountlink_web, do: "Approved", else: "Draft"
    %{
      "member_id" => params.member.id,
      "facility_id" => params.facility.id,
      "coverage_id" => params.coverage.id,
      "step" => 3,
      "created_by_id" => params.result.user.id,
      "origin" => params.params["origin"],
      "is_peme?" => true,
      "status" => ap_status
     }
  end

  defp peme_params(authorization, params, package_facility_rate) do
    date_created = Date.utc_today()
    valid_until = Date.to_string(Date.add(date_created, 2))
    %{
      admission_date: params.params["admission_datetime"],
      discharge_date: params.params["discharge_datetime"],
      authorization_id: authorization.id,
      benefit_package_id: params.benefit_packages2.id,
      benefit_code: params.benefit.code,
      package: [
        id: params.package.id,
        code: params.package.code,
        name: params.package.name
      ],
      member_id: params.member.id,
      room_id: "",
      package_facility_rate: package_facility_rate,
      payor_procedure: params.payor_procedures,
      product_benefit: params.product_benefit,
      product_benefit_id: params.product_benefit.id,
      valid_until: valid_until,
      member_product_id: params.member_product.id,
      origin: params.params["origin"],
      internal_remarks: authorization.internal_remarks,
      product_id: params.product.id,
      facility_id: params.facility.id,
      coverage_id: params.coverage.id,
      user_id: params.result.user.id,
      member: params.member,
      peme: params.peme,
      facility_code: params.params["facility_code"],
      package_code: params.package.code,
      package_name: params.package.name
    }
  end

  def request_peme_to_providerlink(conn, authorization, evoucher, member, pm_param) do
    with {:ok, changeset} <- PEMEValidator.request_peme(pm_param),
         {:ok, response} <- AuthorizationAPI.request_peme_loa_providerlink(pm_param, evoucher),
         authorization <- AuthorizationAPI.get_peme_authorization(authorization.id)
    do
      request_peme_to_paylink(conn, member, pm_param, authorization)
    else
      {:error, "Error creating loa in providerlink."} ->
        error_msg(conn, 400, "Error creating loa in providerlink")
      {:error} ->
        error_msg(conn, 400, "Error creating loa")
      {:unable_to_login, "Unable to login to ProviderLink API"} ->
        error_msg(conn, 400, "Unable to login in ProviderLink")
      _ ->
        error_msg(conn, 400, "Error")
    end
  end

  defp request_peme_to_paylink(conn, member, pm_param, authorization) do
    client_ip = UtilityContext.get_client_ip(conn)
    pm_param = Map.put(pm_param, :ip, client_ip)

    with {:ok, response} <- AuthorizationAPI.request_peme_in_paylink(conn.scheme, member, pm_param, authorization) do
      authorization_log(authorization.id, member, "PEME: Succesfully Submitted Loa to Paylink")
      MemberContext.update_peme_authorization(pm_param.peme, authorization.id)
      json(conn, %{message: "Succesfully Created Peme Loa"})
    else
      {:error_loa_params, resp_error_message} ->
        authorization_log(authorization.id, member, resp_error_message)
      {:error_loa, "Error Submitting Loa to Paylink"} ->
        authorization_log(authorization.id, member, "PEME: Error Submitting Loa to PayLink")
      {:error_loa, "Unable to sign-in in Paylink"} ->
        authorization_log(authorization.id, member, "PEME: Unable to log-in in Paylink")
      {:unable_to_login, "Unable to login to CVV API"} ->
        pl1_peme_log(member, "Unable to log-in to CVV API")
      {:unable_to_login, reason} ->
        pl1_peme_log(member, "Unable to log-in #{reason}")
      {:error_member, errors} ->
        error = Enum.join(errors, ", ")
        pl1_peme_log(member, error <> " " <> "in Payorlink one")
      {:error_syntax, response_message} ->
        pl1_peme_log(member, response_message <> " " <> "in PayorLink 1.0")
      {:unable_to_log_in_payorlink_one} ->
        pl1_peme_log(member, "Unable to Log-in PayorLink 1.0")
      {:error_api_save_peme_member} ->
        pl1_peme_log(member, "Error api save peme member PayorLink 1.0")
    end
  end

  defp pl1_peme_log(member, message) do
    MemberContext.payorlink_one_peme_member_log(member.created_by_id, member.id, message)
  end

  defp authorization_log(authorization_id, member, message) do
    AuthorizationContext.insert_log(%{
      authorization_id: authorization_id,
      user_id: member.created_by_id,
      message: message})
  end

  defp get_loa_diagnosis_peme(loa) do
    loa.authorization_diagnosis
    |> Enum.map(fn(x) ->
      %{
        "ICDCode" => x.diagnosis.code,
        "ICDDesc" => x.diagnosis.description
       }
    end)
  end

  # defp get_loa

  def reschedule_loa(conn, %{"id" => id}) do
    authorization = AuthorizationContext.get_authorization_by_id(id)
    with {:ok, old_authorization} <- AuthorizationContext.update_authorization_reschedule_status(authorization),
         {:ok, new_authorization} <- AuthorizationContext.copy_authorization(authorization) do
          new_authorization = AuthorizationContext.get_authorization_by_id(new_authorization.id)
          new_authorization =
            new_authorization
            |> Map.merge(%{old_authorization_id: old_authorization.id})
           params = %{authorization_id: new_authorization.id}
          conn
          |> put_status(200)
          |> render(AuthorizationView, "reschedule_loa.json", loa: new_authorization)
    else
      _ ->
        conn
    end
  end

 def generate_transaction_no(conn, _params) do
    transaction_no = AuthorizationContext.generate_transaction_no()
    conn
    |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: transaction_no)
 end

  def request_loe_pos_terminal(conn, params) do
    with {:ok} <- validate_required_for_pos_terminal(params),
         {:ok, params} <- validate_pos_terminal_params(params)
    do
      user = PG.current_resource_api(conn)
      {:ok, authorization} = create_authorization_pos_terminal(params, user.id)
      authorization = AuthorizationContext.get_authorization_by_id(authorization.id)
      conn
      |> put_status(200)
      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "authorization_pos_terminal.json", loa: authorization)
    else
      {:error, messages} ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "error.json", message: Enum.join(messages, ", "), code: 404)
      _ ->
        conn
        |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "error.json", message: "Internal Server Error", code: 500)
    end
  end

  defp validate_required_for_pos_terminal(params) do
    error = []
    if is_nil(params["card_no"]) || params["card_no"] == "" do
      error = error ++ ["Please enter a card no"]
    end
    if is_nil(params["facility_code"]) || params["facility_code"] == "" do
      error = error ++ ["Please enter facility code"]
    end
    if is_nil(params["coverage_code"]) || params["coverage_code"] == "" do
      error = error ++ ["Please enter coverage code"]
    end
    if is_nil(params["loe_no"]) || params["loe_no"] == "" do
      error = error ++ ["Please enter loe no"]
    end
    if error != [] do
      {:error, error}
    else
      {:ok}
    end
  end

  defp validate_pos_terminal_params(params) do
    error = []
    return_params = %{}
    {status, data} = validate_card_number_pos_terminal(params["card_no"])
    if status == :ok do
      return_params = Map.put_new(return_params, :member, data)
    else
      error = error ++ [data]
    end
    {status, data} = validate_coverage(params["coverage_code"])
    if status == :ok do
      return_params = Map.put_new(return_params, :coverage, data)
    else
      error = error ++ [data]
    end
    {status, data} = validate_facility(params["facility_code"])
    if status == :ok do
      return_params = Map.put_new(return_params, :facility, data)
    else
      error = error ++ [data]
    end
    if error != [] do
      {:error, error}
    else
      {status, data} = validate_facility_access(return_params.member.id,
                                                return_params.coverage.id,
                                                return_params.facility.id)
      if status == :ok do
        return_params = Map.put_new(return_params, :loe_no, params["loe_no"])
        {:ok, return_params}
      else
        {:error, [data]}
      end
    end
  end

  defp validate_card_number_pos_terminal(card_no) do
    cond do
      Regex.match?(~r/^[0-9]*$/, card_no) == false ->
        {:error, "Card no should be numberic only"}
      String.length(card_no) != 16 ->
        {:error, "Card no should be 16-digits"}
      true ->
        member = MemberContext.get_member_by_card_no(card_no)
        if is_nil(member) do
          {:error, "Member not found with this card no"}
        else
          {:ok, member}
        end
    end
  end

  defp validate_coverage(code) do
    coverage = CoverageContext.get_coverage_by_code(code)
    if is_nil(coverage) do
      {:error, "Coverage does not exist"}
    else
      {:ok, coverage}
    end
  end

  defp validate_facility(code) do
    facility = FacilityContext.get_facility_by_code(code)
    cond do
      is_nil(facility) ->
        {:error, "Facility does not exist"}
      facility.status != "Affiliated" && facility.step < 7 ->
        {:error, "Facility not affiliated"}
      true ->
        {:ok, facility}
    end
  end

  defp validate_facility_access(member_id, coverage_id, facility_id) do
    facilities = FacilityContextAPI.search_all_facility_filtered_from_member_coverage(member_id, coverage_id)
    facility_ids = Enum.map(facilities, & (&1.id))
    if Enum.member?(facility_ids, facility_id) do
      {:ok, facilities}
    else
      {:error, "Member not eligible for selected Facility"}
    end
  end

  defp create_authorization_pos_terminal(params, user_id) do
    transaction_no = AuthorizationContext.generate_transaction_no()
    params = %{
      loe_number: params.loe_no,
      member_id: params.member.id,
      coverage_id: params.coverage.id,
      facility_id: params.facility.id,
      step: 4,
      origin: "POS Terminal",
      swipe_datetime: Ecto.DateTime.cast!(:calendar.local_time()),
      transaction_no: transaction_no,
      created_by_id: user_id,
      status: "Pending"
    }
    AuthorizationAPI.create_loa_for_pos_terminal(params)
  end

  def request_loa_op_lab(conn, params) do
    member = MemberContext.get_a_member!(params["member_id"])
    coverage = CoverageContext.get_coverage_by_name("OP Laboratory")
    authorization = AuthorizationContext.get_authorization_by_id(params["authorization_id"])
    OPLabValidator.setup_products_of_member(member, coverage, authorization)

    compute_discount(params, authorization.authorization_amounts)
    compute_special_approval_amount(params, authorization.authorization_amounts)
  end

  def compute_discount(params, auth_amount) do
    pwd =
      with true <- params["pwd"],
           true <- not is_nil(params["pwd_discount"])
      do
        %{pwd_discount: params["pwd_discount"]}
      else
        _ ->
          %{}
      end

    senior =
      with true <- params["senior"],
           true <- not is_nil(params["senior_discount"])
      do
        %{senior_discount: params["senior_discount"]}
      else
        _ ->
          %{}
      end

    result = Map.merge(pwd, senior)

    if result != %{} do
      AuthorizationContext.update_senior_pwd_amount(auth_amount, result)
    end
  end

  def compute_special_approval_amount(params, auth_amount) do
    if not is_nil(params["special_approval_amount"]) do
      AuthorizationContext.update_special_approval_amount(
        auth_amount,
        %{special_approval_amount: params["special_approval_amount"]}
      )
    end
  end

  def update_request_acu(user, params) do
    authorization_id = params["authorization_id"]
    origin = params["origin"]
    card_no = params["card_no"]
    facility_code = params["facility_code"]
    coverage_code = params["coverage_code"]
    admission_date = params["admission_date"]
    discharge_date = params["discharge_date"]
    date_created = Date.utc_today()
    valid_until = Date.to_string(Date.add(date_created, 2))

    member = MemberContext.get_member_by_card_no(card_no)
    member = MemberContext.get_a_member!(member.id)
    facility = FacilityContext.get_facility_by_code(facility_code)
    coverage = CoverageContext.get_coverage_by_code(coverage_code)

    member_products =
      for member_product <- member.products do
        member_product
      end

    member_products =
      member_products
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten()

    member_product =
      AuthorizationContext.get_member_product_with_coverage_and_tier(
        member_products,
        coverage.id
      )

    product = if is_nil(member_product.account_product) do
      nil
    else
      member_product.account_product.product
    end

    product_id = if is_nil(product) do
      nil
    else
      product.id
    end

    product_benefit =
      MemberContext.get_acu_package_based_on_member(
        member,
        member_product
      )

    benefit = product_benefit.benefit
    benefit_package =
      MemberContext.get_acu_package_based_on_member_for_schedule(
        member,
        member_product
      )

    benefit_package = benefit_package
                      |> List.first()

    package = benefit_package.package

    authorization = AuthorizationContext.get_authorization_by_id(
      authorization_id
    )
    acu_params = %{
      authorization_id: authorization.id,
      user_id: user.id,
      member_id: authorization.member_id,
      facility_id: authorization.facility_id,
      coverage_id: authorization.coverage_id,
      room_id: "",
      benefit_package_id: benefit_package.id,
      admission_date: admission_date,
      discharge_date: discharge_date,
      product_id: product_id,
      product: product,
      internal_remarks: authorization.internal_remarks,
      valid_until: valid_until,
      member_product_id: member_product.id,
      product_benefit_id: product_benefit.id,
      origin: origin,
      product_benefit: product_benefit
    }

    acu_params = if is_nil(params["acu_schedule_id"]) do
      acu_params
    else
      acu_params
      |> Map.put_new(:acu_schedule_id, params["acu_schedule_id"])
    end
    with {:ok, changeset} <- ACUValidator.request_acu(acu_params) do
      authorization =
        AuthorizationContext.get_authorization_by_id(
          changeset.changes.authorization_id
        )
       {:ok, authorization} = AuthorizationAPI.update_status_to_approved(authorization_id)
       {:ok, authorization}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, "Error inserting loa 2nd validation"}
      {:invalid_coverage, error} ->
        {:error, "Invalid coverage"}
      _ ->
        {:error, "Error in setup loa 2nd validation"}
    end
  end

  def print_pdf(conn, params) do
    with {:ok, changeset} <- AuthorizationAPI.validate_print_required(params),
         authorization = %Authorization{} <- AuthorizationContext.get_authorization_by_loa_number(params["loa_number"])
    do
      case authorization.coverage.code do
      "ACU" ->
        print_acu(conn, authorization)

      "OPC" ->
        with {:ok, changeset} <- AuthorizationAPI.op_consult?(changeset) do
          if changeset.changes[:copy] == "original" do
            print_original_consult(conn, authorization)
          else
            print_duplicate_consult(conn, authorization)
          end
        else
          {:error, changeset} ->
            conn
            |> put_status(400)
            |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "changeset_error.json", changeset: changeset)
          _ ->
            conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Invalid OP Consult Authorization.")
        end
      _ ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Invalid Authorization. Can only print OP Consult and ACU")
      end
    else
      _ ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "LOA not found!")
    end
  end

  def print_acu(conn, authorization) do
    member = MemberContext.get_member_any_status(authorization.member_id)

    member_products =
      for member_product <- member.products do
        member_product
      end

    member_products =
      member_products
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten()

    member_product =
      AuthorizationContext.get_member_product_with_coverage_and_tier(
        member_products,
        authorization.coverage.id
      )

    product = member_product.account_product.product

    product_benefit =
      MemberContext.get_acu_package_based_on_member(
        member,
        member_product
      )

    benefit = product_benefit.benefit
    # benefit_package = List.first(benefit.benefit_packages)
    # package = benefit_package.package
    benefit_package =
      MemberContext.get_acu_package_based_on_member_for_schedule(
        member,
        member_product
      )

    benefit_package = benefit_package
                      |> List.first()
    package = benefit_package.package

    html =
      Phoenix.View.render_to_string(
        Innerpeace.PayorLink.Web.AuthorizationView,
        "print/acu_summary.html",
        conn: conn,
        authorization: authorization,
        member: member,
        package: package
      )

    {date, time} = :erlang.localtime()
    unique_id = Enum.join(Tuple.to_list(date)) <> Enum.join(Tuple.to_list(time))
    filename = "#{unique_id}"

    with {:ok, content} <-
           PdfGenerator.generate_binary(html, filename: filename, delete_temporary: true) do
        conn
        |> put_status(200)
        |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "https://payorlink-ip-ist.medilink.com.ph/authorizations/#{authorization.id}/print_authorization")
    else
      {:error, _reason} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Failed to print authorization")
    end
  end

  def print_original_consult(conn, authorization) do
    member = MemberContext.get_member_any_status(authorization.member_id)

    html =
      Phoenix.View.render_to_string(
        Innerpeace.PayorLink.Web.AuthorizationView,
        "print/original_consult_summary.html",
        authorization: authorization,
        member: member,
        conn: conn
      )

    {date, time} = :erlang.localtime()
    unique_id = Enum.join(Tuple.to_list(date)) <> Enum.join(Tuple.to_list(time))
    filename = "#{authorization.coverage.code}_#{member.first_name}_#{unique_id}"

    with {:ok, content} <-
           PdfGenerator.generate_binary(html, filename: filename, delete_temporary: true) do
        conn
        |> put_status(200)
        |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "https://payorlink-ip-ist.medilink.com.ph/authorizations/#{authorization.id}/original/print_authorization")
    else
      {:error, _reason} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Failed to print authorization")
    end
  end

  def print_duplicate_consult(conn, authorization) do
    member = MemberContext.get_member_any_status(authorization.member_id)

    html =
      Phoenix.View.render_to_string(
        Innerpeace.PayorLink.Web.AuthorizationView,
        "print/duplicate_consult_summary.html",
        authorization: authorization,
        member: member,
        conn: conn
      )

    {date, time} = :erlang.localtime()
    unique_id = Enum.join(Tuple.to_list(date)) <> Enum.join(Tuple.to_list(time))
    filename = "#{authorization.coverage.code}_#{member.first_name}_#{unique_id}"

    with {:ok, content} <-
           PdfGenerator.generate_binary(html, filename: filename, delete_temporary: true) do
      conn
        |> put_status(200)
        |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "https://payorlink-ip-ist.medilink.com.ph/authorizations/#{authorization.id}/duplicate/print_authorization")
    else
      {:error, _reason} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Failed to print authorization")
    end
  end

  # Vendor

  def vendor_print_pdf(conn, params) do
    with {:ok, changeset} <- AuthorizationAPI.validate_print_required(params),
         authorization = %Authorization{} <- AuthorizationContext.get_authorization_by_loa_number(params["loa_number"])
    do
      case authorization.coverage.code do
      "ACU" ->
        print_acu(conn, authorization)

      "OPC" ->
        with {:ok, changeset} <- AuthorizationAPI.op_consult?(changeset) do
          if changeset.changes[:copy] == "original" do
            vendor_print_original_consult(conn, authorization)
          else
            vendor_print_duplicate_consult(conn, authorization)
          end
        else
          {:error, changeset} ->
            conn
            |> put_status(400)
            |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "changeset_error.json", changeset: changeset)
          _ ->
            conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Invalid OP Consult Authorization.")
        end
      _ ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Invalid Authorization. Can only print OP Consult and ACU")
      end
    else
      _ ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "LOA not found!")
    end
  end

  def vendor_print_original_consult(conn, authorization) do
    authorization =
      authorization
      |> Map.put(:print_type, "original")

    member = MemberContext.get_member_any_status(authorization.member_id)

    html =
      Phoenix.View.render_to_string(
        Innerpeace.PayorLink.Web.AuthorizationView,
        "print/original_consult_summary.html",
        authorization: authorization,
        member: member,
        conn: conn
      )

    {date, time} = :erlang.localtime()
    unique_id = Enum.join(Tuple.to_list(date)) <> Enum.join(Tuple.to_list(time))
    filename = "#{authorization.coverage.code}_#{member.first_name}_#{unique_id}"

    with {:ok, content} <-
           PdfGenerator.generate_binary(html, filename: filename, delete_temporary: true) do
        conn
        |> put_status(200)
        |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "vendor_op_consult_print.json", authorization: authorization, conn: conn)
    else
      {:error, _reason} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Failed to print authorization")
    end
  end

  def vendor_print_duplicate_consult(conn, authorization) do
    authorization =
      authorization
      |> Map.put(:print_type, "duplicate")
    member = MemberContext.get_member_any_status(authorization.member_id)

    html =
      Phoenix.View.render_to_string(
        Innerpeace.PayorLink.Web.AuthorizationView,
        "print/duplicate_consult_summary.html",
        authorization: authorization,
        member: member,
        conn: conn
      )

    {date, time} = :erlang.localtime()
    unique_id = Enum.join(Tuple.to_list(date)) <> Enum.join(Tuple.to_list(time))
    filename = "#{authorization.coverage.code}_#{member.first_name}_#{unique_id}"

    with {:ok, content} <-
           PdfGenerator.generate_binary(html, filename: filename, delete_temporary: true) do
      conn
        |> put_status(200)
        |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "vendor_op_consult_print.json", authorization: authorization, conn: conn)
    else
      {:error, _reason} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Failed to print authorization")
    end
  end

  def vendor_get_acu_details(conn, params) do
    user = PG.current_resource_api(conn)
    origin = params["origin"]
    card_no = params["card_no"]
    facility_code = params["facility_code"]
    coverage_code = params["coverage_code"]

    member = MemberContext.get_member_by_card_no(card_no)
    member = MemberContext.get_a_member!(member.id)
    facility = FacilityContext.get_facility_by_code(facility_code)

    with coverage = %Coverage{} <- CoverageContext.get_coverage_by_code(coverage_code) do

      member_products =
        for member_product <- member.products do
          member_product
        end

      member_products =
        member_products
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.flatten()

      member_product =
        AuthorizationContext.get_member_product_with_coverage_and_tier(
          member_products,
          coverage.id
        )

      product_benefit =
        MemberContext.get_acu_package_based_on_member(
          member,
          member_product
        )
      pbl = ProductContext.get_product_benefit(product_benefit.id).product_benefit_limits
      product_benefit_limit =
        pbl
        |> List.first()
      limit_amount = if is_nil(product_benefit_limit) do
        Decimal.new(0)
      else
        product_benefit_limit.limit_amount || Decimal.new(0)
      end
      benefit = product_benefit.benefit
      # benefit_package = List.first(benefit.benefit_packages)
      # package = benefit_package.package
      benefit_package =
        MemberContext.get_acu_package_based_on_member_for_schedule(
          member,
          member_product
        )

      with {:valid, benefit_package} <- check_benefit_package(benefit_package),
           true <- AuthorizationAPI.validate_acu(member, coverage),
           true <- AuthorizationAPI.validate_acu_pf(facility.id, member.id, coverage)
      do
        package = benefit_package.package
        payor_procedures = AuthorizationView.payor_procedures(package, member)

        package_facility_rate =
          AuthorizationView.package_facility_rate(
            package.package_facility,
            facility.id
          )

        package =
          package
          |> Map.merge(%{package_facility_rate: package_facility_rate})

        benefit =
          benefit
          |> Map.merge(%{limit_amount: limit_amount})

        if benefit.acu_type == "Executive" and benefit.acu_coverage == "Inpatient" do
          if Map.has_key?(params, "discharge_date") == false or is_nil(params["discharge_date"])
             or params["discharge_date"] == ""
          do
            conn
            |> put_status(400)
            |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "vendor_acu_executive.json", benefit: benefit)
          else
            with true <- UtilityContext.validate_dates_format(params["admission_date"], "Service Date"),
                 true <- UtilityContext.validate_dates_format(params["discharge_date"], "Discharge Date")
            do
              authorization_params = %{
                "member_id" => member.id,
                "facility_id" => facility.id,
                "coverage_id" => coverage.id,
                "step" => 3,
                "created_by_id" => user.id,
                "origin" => origin
              }

              with {:ok, authorization} <-
                AuthorizationContext.create_authorization_api(
                  user.id,
                  authorization_params
                )
              do
                %{
                  "amount" => package.package_facility_rate,
                  "authorization_id" => authorization.id,
                  "card_no" => member.card_no,
                  "coverage_code" => "ACU",
                  "facility_code" => params["facility_code"],
                  "member_id" => member.id,
                  "origin" => "payorlink",
                  "valid_until" => "2090-10-10",
                  "verification_type" => "member_details",
                  "discharge_date" => params["discharge_date"],
                  "admission_date" => params["admission_date"]
                }
              else
                {:error, changeset} ->
                  conn
                  |> put_status(400)
                  |> render(ErrorView, "changeset_error.json", changeset: changeset)
              end
            else
              {false, date} ->
                 error_msg(conn, 400, "#{date} format is invalid. Format must be {YYYY-MM-DD}")
            end

          end
        else
          authorization_params = %{
            "member_id" => member.id,
            "facility_id" => facility.id,
            "coverage_id" => coverage.id,
            "step" => 3,
            "created_by_id" => user.id,
            "origin" => origin
          }

          with {:ok, authorization} <-
            AuthorizationContext.create_authorization_api(
              user.id,
              authorization_params
            )
          do
            %{
              "amount" => package.package_facility_rate,
              "authorization_id" => authorization.id,
              "card_no" => member.card_no,
              "coverage_code" => "ACU",
              "facility_code" => params["facility_code"],
              "member_id" => member.id,
              "origin" => "payorlink",
              "valid_until" => "2090-10-10",
              "verification_type" => "member_details",
              "admission_date" => params["admission_date"]
            }
          else
            {:error, changeset} ->
              conn
              |> put_status(400)
              |> render(ErrorView, "changeset_error.json", changeset: changeset)
          end
        end
      else
        {:old_data} ->
          error_msg(conn, 400, "Product is old data, try to create new product.")
        {:invalid_coverage, error} ->
          error_msg(conn, 400, error)
      end
    else
      _ ->
        error_msg(conn, 400, "Invalid Coverage")
    end
  end

  def vendor_request_acu(conn, params) do
    user = PG.current_resource_api(conn)
    authorization_id = params["authorization_id"]
    origin = params["origin"]
    card_no = params["card_no"]
    facility_code = params["facility_code"]
    coverage_code = params["coverage_code"]
    admission_date = params["admission_date"]
    discharge_date = params["discharge_date"]
    date_created = Date.utc_today()
    valid_until = Date.to_string(Date.add(date_created, 2))

    member = MemberContext.get_member_by_card_no(card_no)
    member = MemberContext.get_a_member!(member.id)
    facility = FacilityContext.get_facility_by_code(facility_code)
    coverage = CoverageContext.get_coverage_by_code(coverage_code)

    member_products =
      for member_product <- member.products do
        member_product
      end

    member_products =
      member_products
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten()

    member_product =
      AuthorizationContext.get_member_product_with_coverage_and_tier(
        member_products,
        coverage.id
      )

    product = member_product.account_product.product
    product_benefit =
      MemberContext.get_acu_package_based_on_member(
        member,
        member_product
      )

    benefit = product_benefit.benefit
    benefit_package = List.first(benefit.benefit_packages)
    package = benefit_package.package

    authorization = AuthorizationContext.get_authorization_by_id(
      authorization_id
    )

    acu_params = %{
      authorization_id: authorization.id,
      user_id: user.id,
      member_id: authorization.member_id,
      facility_id: authorization.facility_id,
      coverage_id: authorization.coverage_id,
      room_id: "",
      benefit_package_id: benefit_package.id,
      admission_date: admission_date,
      discharge_date: discharge_date,
      product_id: product.id,
      product: product,
      internal_remarks: authorization.internal_remarks,
      valid_until: valid_until,
      member_product_id: member_product.id,
      product_benefit_id: product_benefit.id,
      origin: origin,
      product_benefit: product_benefit
    }

    with {:ok, changeset} <- ACUValidator.request_acu(acu_params) do
      authorization =
        AuthorizationContext.get_authorization_by_id(
          changeset.changes.authorization_id
        )
        vendor_print_acu(conn, authorization)
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(400)
        |> render(ErrorView, "changeset_error.json", changeset: changeset)
      {:invalid_coverage, error} ->
        error_msg(conn, 400, error)
    end
  end

  def vendor_print_acu(conn, authorization) do
    member = MemberContext.get_member_any_status(authorization.member_id)

    member_products =
      for member_product <- member.products do
        member_product
      end

    member_products =
      member_products
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten()

    member_product =
      AuthorizationContext.get_member_product_with_coverage_and_tier(
        member_products,
        authorization.coverage.id
      )

    product = member_product.account_product.product

    product_benefit =
      MemberContext.get_acu_package_based_on_member(
        member,
        member_product
      )

    benefit = product_benefit.benefit
    # benefit_package = List.first(benefit.benefit_packages)
    # package = benefit_package.package
    benefit_package =
      MemberContext.get_acu_package_based_on_member_for_schedule(
        member,
        member_product
      )

    benefit_package = benefit_package
                      |> List.first()
    package = benefit_package.package

    html =
      Phoenix.View.render_to_string(
        Innerpeace.PayorLink.Web.AuthorizationView,
        "print/acu_summary.html",
        conn: conn,
        authorization: authorization,
        member: member,
        package: package
      )

    {date, time} = :erlang.localtime()
    unique_id = Enum.join(Tuple.to_list(date)) <> Enum.join(Tuple.to_list(time))
    filename = "#{unique_id}"

    with {:ok, content} <-
           PdfGenerator.generate_binary(html, filename: filename, delete_temporary: true) do
        conn
        |> put_status(200)
        |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "vendor_acu.json", authorization: authorization, conn: conn)
    else
      {:error, _reason} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Failed to print authorization")
    end
  end

  def vendor_get_peme_details(conn, params) do
    user = PG.current_resource_api(conn)
    origin = params["origin"]
    card_no = params["card_no"]
    facility_code = params["facility_code"]
    coverage_code = params["coverage_code"]

    member = MemberContext.get_member_by_card_no(card_no)
    member = MemberContext.get_a_member!(member.id)
    facility = FacilityContext.get_facility_by_code(facility_code)
    coverage = CoverageContext.get_coverage_by_code(coverage_code)

    member_products =
      for member_product <- member.products do
        member_product
      end

    member_products =
      member_products
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten()

    member_product =
      AuthorizationContext.get_member_product_with_coverage_and_tier(
        member_products,
        coverage.id
      )

    product = member_product.account_product.product

    benefit_package =
      MemberContext.get_peme_package_based_on_member_for_schedule(
        member,
        member_product
    )

    peme = MemberContext.get_peme_by_member_id(member.id)
    benefit_package =
      benefit_package
      |> Enum.find(&(&1.package.id == peme.package_id))
    benefit = BenefitContext.get_benefit(benefit_package.benefit_id)
    package = benefit_package.package
    payor_procedures = AuthorizationView.payor_procedures(package, member)

    with true <- AuthorizationAPI.validate_peme_existing(member, coverage, facility.id),
         true <- AuthorizationAPI.validate_peme(member, coverage),
         true <- AuthorizationAPI.validate_peme_pf(facility.id, member.id, coverage)
    do
      package_facility_rate =
        AuthorizationView.package_facility_rate(
          package.package_facility,
          facility.id
        )

      package =
        package
        |> Map.merge(%{package_facility_rate: package_facility_rate})

      authorization_params = %{
        "member_id" => member.id,
        "facility_id" => facility.id,
        "coverage_id" => coverage.id,
        "step" => 3,
        "created_by_id" => user.id,
        "origin" => origin,
        "is_peme" => true
      }

      with {:ok, authorization} <-
        AuthorizationContext.create_authorization_api(
          user.id,
          authorization_params
        )
      do
        %{
          "amount" => package.package_facility_rate,
          "authorization_id" => authorization.id,
          "card_no" => member.card_no,
          "coverage_code" => "PEME",
          "facility_code" => params["facility_code"],
          "member_id" => member.id,
          "origin" => "payorlink",
          "valid_until" => "2090-10-10",
          "admission_date" => params["admission_date"]
        }
      else
        {:error, changeset} ->
          conn
          |> put_status(400)
          |> render(ErrorView, "changeset_error.json", changeset: changeset)
      end
    else
      {:invalid_coverage, error} ->
        error_msg(conn, 400, error)
    end
  end

  def validate_coverage_peme(conn, params) do
    case AuthorizationAPI.validate_coverage_params(params) do
      {:ok} ->
        "Eligible"
      {:error, changeset} ->
        message = coverage_validation1(changeset, "PEME")
        message =
          if is_nil(message) do
            coverage_validation2(changeset)
          else
            message
          end
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: message)
      {:not_covered, message} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Member is not allowed to access this facility")
    end
  end

  def approve_loa_status(conn, params) do
    user = PG.current_resource_api(conn)
    loa_id = params["authorization_id"]
    with {:ok, authorization} <- AuthorizationAPI.approve_loa_status(loa_id, user.id) do
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "approve_loa.json", authorization: authorization)
    else
      true ->
       conn
       |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "Invalid parameters")
      _ ->
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "loa not found")
    end
  end

  def get_claims(conn, _params) do
    claims = AuthorizationAPI.get_claims()
    if !Enum.empty?(claims) do
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "claims.json", claims: claims)
    else
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "claims not found")
    end
  end

  def get_claims2(conn, _params) do
    batch = AuthorizationAPI.setup_claims_batch()
    if batch do
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "claims2.json", claims: batch)
    else
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "claims not found")
    end
  end

  def update_migrated_claim(conn, params) do
    if is_nil(params["BatchNo"]) ||  params["BatchNo"] == "" do
      conn
      |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "Batch No is required")
    else
      if Enum.empty?(params["LOA"]) or params["LOA"] == [] do
        conn
        |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "LOA cannot be empty")
      else
        params_claims = Enum.map(params["LOA"], fn(loa) ->
          %{
            id: loa["UID"],
            batch_no: params["BatchNo"],
            loe_no: loa["LOE"]
          }
        end)
        AuthorizationAPI.update_claim_migrated_by_batch(params["BatchNo"])

        Exq.Enqueuer.start_link

        Exq.Enqueuer
        |> Exq.Enqueuer.enqueue(
          "update_migrated_claim_job",
          "Innerpeace.Db.Worker.Job.UpdateMigratedClaim",
          [params_claims])
        conn
        |> render(Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", message: "Claim Migrated successfully updated")
      end
    end
  end
end
