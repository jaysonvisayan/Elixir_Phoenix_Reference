defmodule MemberLinkWeb.SearchController do
  use MemberLinkWeb, :controller

  # alias Innerpeace.Db.Repo
  alias MemberLink.Guardian.Plug
  alias Innerpeace.Db.Base.{
    PractitionerContext,
    SpecializationContext,
    MemberContext,
    FacilityContext,
    TranslationContext,
    AuthorizationContext,
    CoverageContext,
    ProductContext,
    DiagnosisContext
  }
  alias Innerpeace.Db.Validators.{
    OPConsultValidator
  }

  alias Ecto.Date
  alias Innerpeace.Db.Base.Api.FacilityContext, as: ApiFacilityContext
  # alias Innerpeace.Db.Schemas.{
    # Specialization,
    # Practitioner,
    # Member,
    # Translation,
    # Authorization
  # }
  alias MemberLink.Guardian, as: MG

  plug :map_specializations when action in [:search_doctors, :get_all_doctors,
                                            :get_all_hospitals, :get_all_doctors_and_hospitals, :search_doctors_submit]

  def search_doctors(conn, params) do
    user = MG.current_resource(conn)
    member = MemberContext.get_member(user.member_id)
    params = Map.merge(params, %{"offset" => 0})
      if conn.assigns.locale == "zh" do
        facilities = ApiFacilityContext.search_all_facility_member(user.member_id, params)
        facilities = ApiFacilityContext.get_translated_facilities(conn, facilities)
        practitioners = PractitionerContext.search_all_practitioners(member.id, params)
        practitioners = PractitionerContext.get_translated_practitioners(conn, practitioners)
      else
        facilities = ApiFacilityContext.search_all_facility_member(user.member_id, params)
        practitioners = PractitionerContext.search_all_practitioners(member.id, params)
      end
    render conn, "search_doctor.html" , member: member, practitioners: practitioners, facilities: facilities
  end

  def filter_doctors(conn, %{"id" => id}) do
    facility = FacilityContext.get_facility!(id)
    render(conn, "facility.json", facility: facility)
  end

  def get_all_doctors(conn, params) do
    user = MG.current_resource(conn)
    if conn.assigns.locale == "zh" do
      practitioners = PractitionerContext.search_all_practitioners(user.member_id, params)
      practitioners = PractitionerContext.get_translated_practitioners(conn, practitioners)
    else
      practitioners = PractitionerContext.search_all_practitioners(user.member_id, params)
    end
    render(conn, "practitioner.json", practitioners: practitioners)
    #render(conn, "search_doctors_list.html", facilities: facilities,
    #practitioners: [], member: member, locale: conn.assigns.locale)
  end

  def get_all_doctors_and_hospitals(conn, params) do
    user = MG.current_resource(conn)
    facilities = ApiFacilityContext.search_all_facility_member(user.member_id, params)
    if conn.assigns.locale == "zh" do
      facilities = ApiFacilityContext.get_translated_facilities(conn, facilities)
    end
    render(conn, "facilities.json", facilities: facilities)
    #render conn, "search_doctor.html", practitioners: practitioners,
    #facilities: facilities, locale: conn.assigns.locale, member: member
  end

  def get_all_hospitals(conn, params) do
    user = MG.current_resource(conn)
    facilities = ApiFacilityContext.search_all_facility_member(user.member_id, params)
    if conn.assigns.locale == "zh" do
      facilities = ApiFacilityContext.get_translated_facilities(conn, facilities)
    end
    render(conn, "facilities.json", facilities: facilities)
    #render conn, "search_hospitals_list.html", facilities: facilities, locale: conn.assigns.locale, member: member
  end

  def search_doctors_submit(conn, params) do
    locale = conn.assigns.locale
    user = MG.current_resource(conn)
    member = MemberContext.get_member(user.member_id)
    search_params = params["search_param"]
    if locale == "zh" do
      cond do
        Enum.any?([params["current_active"] == "Doctors", params["current_active"] == "醫生"]) ->
          search_param = TranslationContext.search_from_translated_values(conn, search_params)
          params =
            params
            |> Map.delete("search_param")
            |> Map.put("search_param", search_param)
          practitioners = PractitionerContext.search_box_practitioner(params, member.id)
          practitioners = PractitionerContext.get_translated_practitioners(conn, practitioners)
          render(conn, "practitioner.json", practitioners: practitioners)
        Enum.any?([params["current_active"] == "Hospitals", params["current_active"] == "醫院"]) ->
          search_param = TranslationContext.search_from_translated_values(conn, search_params)
          params =
            params
            |> Map.delete("search_param")
            |> Map.put("search_param", search_param)
          facilities = ApiFacilityContext.search_facility_memberlink(member.id, params)
          facilities = ApiFacilityContext.get_translated_facilities(conn, facilities)
          render(conn, "facilities.json", facilities: facilities)
        true ->
          search_param = TranslationContext.search_from_translated_values(conn, search_params)
          params =
            params
            |> Map.delete("search_param")
            |> Map.put("search_param", search_param)
          facilities = ApiFacilityContext.search_facility_memberlink(member.id, params)
          facilities = ApiFacilityContext.get_translated_facilities(conn, facilities)
          render(conn, "facilities.json", facilities: facilities)
      end
    else
      cond do
        params["current_active"] == "Doctors" ->
          practitioners = PractitionerContext.search_box_practitioner(params, member.id)
          render(conn, "search_practitioner.json", practitioners: practitioners)
        params["current_active"] == "Hospitals" ->
          facilities = ApiFacilityContext.search_facility_memberlink(member.id, params)
          render(conn, "facilities.json", facilities: facilities)
        true ->
          facilities = ApiFacilityContext.search_facility_memberlink(member.id, params)
          render(conn, "facilities.json", facilities: facilities)
      end
    end
        # search_params = TranslationContext.search_from_translated_values(conn, search_params)
        # practitioners = PractitionerContext.search_box_practitioner(search_params, member.id)
        # practitioners = PractitionerContext.get_translated_practitioners(conn, practitioners)
        # facilities = []
        # render(conn, "search_doctors_list.html", practitioners: practitioners, facilities: facilities, member: member)

      # String.contains?(params["search"]["url"], "/search/hospitals") ->
      #   search_params = TranslationContext.search_from_translated_values(conn, search_params)
      #   search_facility = ApiFacilityContext.search_facility_memberlink(search_params, member.id)
      #   facilities =  search_facility |> List.flatten()
      #   facilities = ApiFacilityContext.get_translated_facilities(conn, facilities)
      #   render conn, "search_hospitals_list.html", facilities: facilities, locale: locale, member: member

      # true ->
      #   search_params = TranslationContext.search_from_translated_values(conn, search_params)
      #   practitioners = PractitionerContext.search_box_practitioner(search_params, member.id)
      #   practitioners = PractitionerContext.get_translated_practitioners(conn, practitioners)
      #   search_facility = ApiFacilityContext.search_facility_memberlink(search_params, member.id)
      #   facilities = search_facility |> List.flatten()
      #   facilities = ApiFacilityContext.get_translated_facilities(conn, facilities)

      #   render conn, "search_doctor.html" , member: member, practitioners: practitioners, facilities: facilities
  end

  def request_loa(conn, params) do
    _facility = FacilityContext.get_facility!(params["facility_id"])
    user = MG.current_resource(conn)
    op_consult = CoverageContext.get_coverage_by_name("OP Consult")
    member = MemberContext.get_member(user.member_id)
    diagnosis = DiagnosisContext.get_diagnosis_by_code("Z71.1")
    param = %{
      "step" => 4,
      "member_id" => member.id,
      "provider_id" => params["facility_id"],
      "admission_datetime" => params["admission_datetime"],
      "chief_complaint" => "Others",
      "chief_complaint_others" => params["chief_complaint"],
      "status" => "Pending",
      "consultation_type" => "initial",
      "coverage_id" => op_consult.id,
      "origin" => "memberlink",
      "version" => 1,
      "diagnosis_id" => diagnosis.id,
    }
    params = Map.merge(params, param)
    with {:ok, authorization} <- AuthorizationContext.create_authorization_api(user.id, params),
         {:ok, loa_consult} <- OPConsultValidator.request(params = params |> Map.merge(%{"authorization_id" => authorization.id, "user_id" => user.id}))
    do
      render(conn, "authorzation.json", %{authorization: loa_consult.changes, transaction_id: authorization.transaction_no})
    else
      _ ->
        raise "Error request"
      #error_msg(conn, 500, "server error")
    end

    #{:ok, authorization} = AuthorizationContext.request_op_consult(user.id, param)
    #ap = %{"authorization_id" => authorization.id, "practitioner_id" => params["id"]}
    #AuthorizationContext.create_authorization_practitioner(ap, user.id)
    #render(conn, "authorzation.json", authorization: authorization)

    # practitioner = PractitionerContext.get_practitioner(practitioner_id)
     #facility = FacilityContext.get_facility!(facility_id)
     #render conn, "request_practitioner.json", practitioner: practitioner, facility: facility
  end

  def check_coverage(conn, _params) do
    user = MG.current_resource(conn)
    op_consult = CoverageContext.get_coverage_by_name("OP Consult")
    op_lab = CoverageContext.get_coverage_by_name("OP Laboratory")
    acu = CoverageContext.get_coverage_by_name("ACU")
    checker_consult = AuthorizationContext.check_coverage_in_product(user.member_id, op_consult.id)
    checker_lab = AuthorizationContext.check_coverage_in_product(user.member_id, op_lab.id)
    checker_acu = AuthorizationContext.check_coverage_in_product(user.member_id, acu.id)
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
    if Enum.empty?(checker_acu) do
      params =
        Map.put_new(params, :acu, false)
    else
      params =
        Map.put_new(params, :acu, true)
    end
      render(conn, "loa_checker.json", checker: params)
  end

  def get_direction(conn, %{"id" => facility_id}) do
    user = MG.current_resource(conn)
    _member = MemberContext.get_member(user.member_id)
    facility = FacilityContext.get_facility!(facility_id)
    render(conn, "direction.json", %{facility: facility})
  end

  def search_intellisense(conn, params) do
    user = MG.current_resource(conn)
    cond do
      params["current_active"] == "Doctors" ->
        practitioners = PractitionerContext.load_all_doctors_for_intellisense(user.member_id, params)
        render(conn, "doctor_intellisense.json", practitioner_facilities: practitioners)
      params["current_active"] == "Hospitals" ->
        facilities = ApiFacilityContext.load_all_facility_for_intellisense(user.member_id, params)
        render(conn, "facility_intellisense.json", facilities: facilities)
      true ->
        facilities = ApiFacilityContext.load_all_facility_for_intellisense(user.member_id)
        render(conn, "facility_intellisense.json", facilities: facilities)
    end
  end

  def get_all_procedures_in_request_acu(conn, params) do
    user = MG.current_resource(conn)
    member = MemberContext.get_a_member!(user.member_id)
    coverage = CoverageContext.get_coverage_by_name("ACU")

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
      AuthorizationContext.get_product_benefit_with_coverage(product, coverage.id)

    _product_benefit_limit = ProductContext.get_a_product_benefit_limit(product_benefit.id)

    benefit = product_benefit.benefit
    benefit_package = List.first(benefit.benefit_packages)
    package = benefit_package.package
    age = age(member.birthdate)

    payor_procedure = for ppp <- package.package_payor_procedure do
      if (ppp.male == true and member.gender == "Male") or (ppp.female == true and member.gender == "Female") do
        if age >= ppp.age_from and age <= ppp.age_to do
          ppp.payor_procedure
        end
      end
    end

    _payor_procedure =
      payor_procedure
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten

    render(conn, "procedures.json", procedures: _payor_procedure)
  end

  def age(%Date{day: d, month: m, year: y}, as_of \\ :now) do
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

  def check_acu_authorization(conn, params) do
    user = MG.current_resource(conn)
    coverage = CoverageContext.get_coverage_by_name("ACU")
    authorization =
      AuthorizationContext.get_authorization_by_coverage_and_member(user.member_id, coverage.id)
    params = %{}
    if Enum.empty?(authorization) do
      params =
        Map.put_new(params, :acu, false)
      params =
        Map.put_new(params, :consult, false)
      params =
        Map.put_new(params, :lab, false)
    else
      params =
        Map.put_new(params, :acu, true)
      params =
        Map.put_new(params, :consult, false)
      params =
        Map.put_new(params, :lab, false)
    end
    render(conn, "loa_checker.json", checker: params)
  end

  defp map_specializations(conn, _) do
    specializations = SpecializationContext.get_all_specializations_search()
    if conn.assigns.locale == "zh" do
      specializations = SpecializationContext.get_translated_specializations(conn, specializations)
    end
    assign(conn, :specializations, specializations)
  end

  def load_affiliated_facilities(conn, %{"member_id" => member_id}) do
    case MemberContext.get_acu_affiliated_facilities(member_id) do
      {:ok, affiliated_facilities} ->
        render(
          conn,
          "view_affiliated_facilities.html",
          facilities: affiliated_facilities,
          result: "show",
          error: "hidden"
        )
      {:error} ->
        render(
          conn,
          "view_affiliated_facilities.html",
          facilities: [],
          result: "hidden",
          error: "show"
        )
    end

  end
end
