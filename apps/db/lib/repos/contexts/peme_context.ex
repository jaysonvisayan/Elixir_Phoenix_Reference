defmodule Innerpeace.Db.Base.PemeContext do
  @moduledoc false

  # alias PayorLink.Guardian, as: PG
  alias Innerpeace.Db.Base.Api.AuthorizationContext, as: AuthorizationContextAPI
  import Ecto.Query
  alias Innerpeace.Db.Validators.PEMEValidator
  alias Innerpeace.{
    Db.Repo,
    Db.Base.MemberContext,
    Db.Base.BenefitContext,
    Db.Base.ProductContext,
    DB.Base.Api.UtilityContext,
    Db.Base.FacilityContext,
    Db.Base.AuthorizationContext,
    Db.Base.CoverageContext
  }

  def request_peme(conn, params, user) do
    result = %{user: user, accountlink_web: true}
    member = has_member_id(params, Map.has_key?(params, "member_id"))
    params =
      params
      |> Map.put("admission_datetime", to_date_string(params["admission_datetime"]))
      |> Map.put("discharge_datetime", to_date_string(params["discharge_datetime"]))

    request_peme(conn, member, params, result)
  end

  defp to_date_string(date) do
      Ecto.Date.to_string(date)
    rescue
       _ ->
        date
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

  # defp check_if_api_or_web(conn, nil) do
  #   user = Guardian.Plug.current_resource(conn)
  #   %{user: user, accountlink_web: true}
  # end

  # defp check_if_api_or_web(conn, current_resource) do
  #   user = PG.current_resource_api(conn)
  #   %{user: user, accountlink_web: false}
  # end

  def request_peme(conn, nil, params, result) do
    {:error,  "Invalid Parameters"}
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
    {:error, "Invalid PEME Member"}
  end

  defp validate_benefits(conn, benefit_packages2, params) do
    member = params.member
    coverage = params.coverage
    facility = params.facility

    benefit = BenefitContext.get_benefit(benefit_packages2.benefit_id)
    product_benefit = get_product_benefit(member, params, benefit)
    product = ProductContext.get_product!(product_benefit.product.id)
    package = benefit_packages2.package
    payor_procedures = get_payor_procedures(package, member) # Changed

    with true <- AuthorizationContextAPI.validate_peme_member(member, coverage, facility.id),
         true <- AuthorizationContextAPI.validate_peme(member, coverage),
         true <- AuthorizationContextAPI.validate_peme_existing(member, coverage, facility.id),
         true <- AuthorizationContextAPI.validate_peme_pf(facility.id, member.id, coverage)
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
        {:error, error}
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
      get_package_facility_rate(
        params.package.package_facility,
        params.facility.id,
        Enum.count(params.package.package_facility)
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
      request_peme_to_paylink(conn, authorization, params.params["evoucher"], params.member, pm_param)
    else
      {:error, changeset} ->
        {:error, "Error in changeset creating LOA"}
    end
  end

  defp authorization_params(params) do
    # ap_status = if params.result.accountlink_web, do: "Approved", else: "Draft"
    %{
      "member_id" => params.member.id,
      "facility_id" => params.facility.id,
      "coverage_id" => params.coverage.id,
      "step" => 3,
      "created_by_id" => params.result.user.id,
      "origin" => params.params["origin"],
      "is_peme?" => true,
      "status" => "Approved"
     }
  end

  defp peme_params(authorization, params, package_facility_rate) do
    authorization = AuthorizationContext.get_authorization_by_id(authorization.id)
    valid_until = get_valid_until(authorization.member)
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
    with {:ok, response} <- AuthorizationContextAPI.request_peme_loa_providerlink(pm_param, evoucher) do
      authorization_log(authorization.id, member, "PEME: Succesfully Submitted Loa to Paylink")
      MemberContext.update_peme_authorization(pm_param.peme, authorization.id)
      {:ok, response}
    else
      {:error, "Error creating loa in providerlink."} ->
        {:error, "Error creating loa in Providerlink."}
      {:error} ->
        {:error, "Error creating loa."}
      {:unable_to_login, "Unable to login to ProviderLink API"} ->
        {:error, "Unable to login in Providerlink"}
      _ ->
        {:error, "Error requesting loa in Providerlink"}
    end
  end

  def get_client_ip(conn) do
    conn.remote_ip
    |> Tuple.to_list
    |> Enum.join(".")
  end

  defp request_peme_to_paylink(conn, authorization, evoucher, member, pm_param) do
    client_ip = get_client_ip(conn)
    pm_param = Map.put(pm_param, :ip, client_ip)

    with {:ok, changeset} <- PEMEValidator.request_peme(pm_param),
         {:ok, response} <- AuthorizationContextAPI.request_peme_in_paylink(conn.scheme, member, pm_param, authorization) do
      request_peme_to_providerlink(conn, authorization, evoucher, member, pm_param)
    else
      {:error_loa_params, resp_error_message} ->
        authorization_log(authorization.id, member, resp_error_message)
        {:error, resp_error_message}
      {:error_loa, "Error Submitting Loa to Paylink"} ->
        authorization_log(authorization.id, member, "PEME: Error Submitting Loa to PayLink")
        {:error, "PEME: Error Submitting Loa to PayLink"}
      {:error_loa, "Unable to sign-in in Paylink"} ->
        authorization_log(authorization.id, member, "PEME: Unable to log-in in Paylink")
        {:error, "PEME: Unable to log-in in Paylink"}
      {:unable_to_login, "Unable to login to PayorAPI/v4/TOKEN"} ->
        pl1_peme_log(member, "Unable to login to PayorAPI/v4/TOKEN")
        {:error, "Unable to login to PayorAPI/v4/TOKEN"}
      {:unable_to_login, reason} ->
        pl1_peme_log(member, "Unable to log-in #{reason}")
        {:error, "Unable to log-in #{reason}"}
      {:error_member, errors} ->
        pl1_peme_log(member, errors <> " " <> "in Payorlink one")
        {:error, "Account does not exist in Payorlink v1.0"}
      {:error_syntax, response_message} ->
        pl1_peme_log(member, response_message <> " " <> "in PayorLink 1.0")
        {:error, response_message <> " " <> "in PayorLink 1.0"}
      {:unable_to_log_in_payorlink_one} ->
        pl1_peme_log(member, "Unable to Log-in PayorLink 1.0")
        {:error, "Unable to Log-in PayorLink 1.0"}
      {:error_api_save_peme_member} ->
        pl1_peme_log(member, "Error api save peme member PayorLink 1.0")
        {:error, "Error api save peme member PayorLink 1.0"}
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

  defp get_payor_procedures(package, member) do
    age = age(member.birthdate)
    gender = member.gender

    package.package_payor_procedure
    |> get_package_payor_procedures(age, gender)
    |> Enum.uniq()
    |> List.delete(nil)
    |> List.flatten
  end

  defp get_package_payor_procedures(ppp, age, gender) do
    Enum.into(ppp, [], &(
      validate_age_n_gender(
        &1,
        age,
        is_male?(&1.male, gender),
        is_female?(&1.female, gender))
    ))
  end

  defp is_male?(male, gender), do: (male and gender == "Male")
  defp is_female?(female, gender), do: (female and gender == "Female")

  defp validate_age_n_gender(ppp, age, male?, female?) when male? or female? do
    get_payor_procedure(ppp.payor_procedure, age, ppp.age_from, ppp.age_to)
  end
  defp validate_age_n_gender(_ppp, _age, _boolean, _boolean_2), do: nil

  defp get_payor_procedure(payor_procedure, age, age_from, age_to)
      when age >= age_from and age <= age_to, do: payor_procedure

  defp get_payor_procedure(_payor_procedure, _age, _age_from, _age_to), do: nil

  defp get_package_facility_rate(_package_facilities, _facility_id, 0), do: Decimal.new(0)
  defp get_package_facility_rate(package_facilities, facility_id, count) when count > 1 do
    package_facilities
    |> Enum.into([], &(get_rate(&1.rate, &1.facility_id, facility_id)))
    |> Enum.uniq()
    |> List.delete(nil)
    |> List.first()
  end

  defp get_package_facility_rate(package_facilities, _facility_id, _count) do
    package_facility = List.first(package_facilities)
    package_facility.rate
  end

  defp get_rate(rate, pf_facility_id, facility_id) when pf_facility_id == facility_id, do: rate
  defp get_rate(_rate, _pf_facility_id, _facility_id), do: nil

  defp age(%Ecto.Date{day: d, month: m, year: y}, as_of \\ :now) do
    do_age({y, m, d}, as_of)
  end

  defp do_age(birthday, :now) do
    {today, _time} = :calendar.now_to_datetime(:erlang.now)
    calc_diff(birthday, today)
  end

  defp do_age(birthday, date), do: calc_diff(birthday, date)

  defp calc_diff({y1, m1, d1}, {y2, m2, d2}) when m2 > m1 or (m2 == m1 and d2 >= d1) do
    y2 - y1
  end

  defp calc_diff({y1, _, _}, {y2, _, _}), do: (y2 - y1) - 1

  defp get_valid_until(nil), do: valid_until()
  defp get_valid_until(member), do: get_valid_until_v2(member.peme)
  defp get_valid_until_v2(nil), do: valid_until()
  defp get_valid_until_v2(peme), do: get_valid_until_v3(peme.date_to)
  defp get_valid_until_v3(nil), do: valid_until()
  defp get_valid_until_v3(date_to), do: "#{date_to}"
  defp valid_until, do: Date.to_string(Date.add(Date.utc_today(), 2))

end
