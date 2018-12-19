defmodule Innerpeace.PayorLink.Web.AuthorizationController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Schemas.{
    Authorization,
    # Facility,
    Member
  }

  alias Decimal
  import Ecto.DateTime

  alias Innerpeace.Db.Base.{
    AuthorizationContext,
    MemberContext,
    FacilityContext,
    DropdownContext,
    DiagnosisContext,
    PractitionerContext,
    CoverageContext,
    ProductContext,
    ProcedureContext,
    RUVContext,
    FacilityContext,
    UserContext,
    RoomContext,
    Api.UtilityContext,
    SpecializationContext,
    UserContext,
    FacilityRoomRateContext,
    ProductContext,
    BenefitContext
  }

  alias Innerpeace.Db.Schemas.AuthorizationLog

  alias Innerpeace.Db.Validators.{
    OPConsultValidator,
    OPLabValidator,
    ACUValidator,
    EmergencyValidator
  }

  alias Innerpeace.PayorLink.Web.AuthorizationView

  alias Innerpeace.Db.Datatables.AuthorizationDatatable

  alias Innerpeace.Db.Utilities.SMS
  alias Innerpeace.Db.Repo
  alias Phoenix.View
  alias Timex.Duration, as: TD

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{authorizations: [:manage_authorizations]},
       %{authorizations: [:access_authorizations]},
     ]] when action in [
       :index,
       :show,
       :authorization_index
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{authorizations: [:manage_authorizations]},
     ]] when not action in [
       :index,
       :show,
       :show_consult,
       :show_laboratory,
       :show_peme,
       :show_acu,
       :show_emergency,
       :show_inpatient,
       :authorization_index
     ]

  plug :valid_uuid?, %{origin: "authorizations"}
  when not action in [:index]

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def new(conn, _params) do
    changeset = Authorization.changeset(%Authorization{})
    render(conn, "step1.html", changeset: changeset)
  end

  def show(conn, %{"id" => id}) do
    authorization = AuthorizationContext.get_authorization_by_id(id)

    if authorization do
      insert_log(conn, id, "Viewed LOA.")
      if not is_nil(authorization.coverage) do
        case authorization.coverage.code do
          "OPC" ->
            show_consult(conn, authorization)

          "OPL" ->
            show_laboratory(conn, authorization)

          "EMRGNCY" ->
            show_emergency(conn, authorization)

          "ACU" ->
            show_acu(conn, authorization)

          "PEME" ->
            show_peme(conn, authorization)

          "IP" ->
            show_inpatient(conn, authorization)
        end
      else
        error_coverage(conn)
      end
    else
      conn
      |> put_flash(:error, "Authorization ID was invalid")
      |> redirect(to: authorization_path(conn, :index))
    end
  end

  def error_coverage(conn) do
    conn
      |> put_flash(:error, "Invalid Coverage")
      |> redirect(to: authorization_path(conn, :index))
  end

  def show_consult(conn, authorization) do
    changeset = Authorization.changeset(authorization)
    special_approval = DropdownContext.get_all_special_approval()
    diagnoses = DiagnosisContext.get_all_diagnoses()
    authorization_files = AuthorizationContext.load_authorization_files(authorization.id)

    practitioners =
      PractitionerContext.get_all_practitioners_by_facility_id(authorization.facility_id)

    member = MemberContext.get_a_member!(authorization.member_id)

    member_products =
      for member_product <- member.products do
        member_product
      end

    _member_products =
      member_products
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten()

    if not Enum.empty?(authorization.authorization_practitioner_specializations) do
      aps =
        List.first(authorization.authorization_practitioner_specializations).practitioner_specialization

      name =
        "#{aps.practitioner.first_name} #{aps.practitioner.middle_name} #{
          aps.practitioner.last_name
        }"

      specialization = aps.specialization.name

      render(
        conn,
        "show.html",
        changeset: changeset,
        special_approval: special_approval,
        diagnoses: diagnoses,
        authorization: authorization,
        practitioners: practitioners,
        member: member,
        authorization_files: authorization_files
      )
    else
      conn
      |> put_flash(
        :error,
        "Invalid authorization data. Authorization has no practitioner specialization"
      )
      |> redirect(to: "/authorizations")
    end
  end

  def show_inpatient(conn, authorization) do
    changeset = Authorization.changeset(authorization)

    authorization_procedures =
      AuthorizationContext.get_all_authorization_procedure_diagnosis(authorization.id)

    authorization_diagnosis =
      AuthorizationContext.get_all_authorization_procedure_diagnosis(authorization.id)

    authorization_rooms =
      AuthorizationContext.get_all_authorization_rooms(authorization.id)

    special_approval = DropdownContext.get_all_special_approval()
    diagnoses = DiagnosisContext.get_all_diagnosis()

    practitioners =
      PractitionerContext.get_all_practitioners_by_facility_id_inpatient(authorization.facility_id)

    member = MemberContext.get_a_member!(authorization.member_id)

    procedures =
      ProcedureContext.get_emergency_payor_procedure_by_facility(authorization.facility_id)

    ruvs = RUVContext.get_ruvs()
    facility_contacts = FacilityContext.get_all_facility_contacts(authorization.facility_id)

    facility_room_rates = FacilityRoomRateContext.get_all_facility_room_rate(authorization.facility_id)

    render(
      conn,
      "show_inpatient.html",
      changeset: changeset,
      procedures: procedures,
      special_approval: special_approval,
      diagnoses: diagnoses,
      authorization_procedures: authorization_procedures,
      authorization_diagnosis: authorization_diagnosis,
      authorization: authorization,
      practitioners: practitioners,
      member: member,
      ruvs: ruvs,
      facility_contacts: facility_contacts,
      facility_room_rates: facility_room_rates,
      authorization_rooms: authorization_rooms
    )
  end

  # def func(peme) do
  #   if is_nil(peme) do
  #     false
  #   else
  #     peme.package.id
  #   end
  # end

  defp validate_peme(peme) do
    if not is_nil(peme) do
      peme.package.id
    else
      false
    end
  end

  def show_peme(conn, authorization) do
    changeset = Authorization.changeset(authorization)
    member = MemberContext.get_a_member!(authorization.member_id)
    coverage = CoverageContext.get_coverage_by_code("PEME")

     member_products =
    AuthorizationContext.get_member_product_with_coverage_and_tier2(
      member.products,
      coverage.id
    )

    peme = MemberContext.get_peme_by_member_id(member.id)
    peme = validate_peme(peme)
     benefit_packages =
      MemberContext.get_peme_package_based_on_member_for_schedule2(
        member,
        member_products
    )
     benefit_packages2 =
      Enum.map(benefit_packages, fn(benefit_package) ->
        benefit_package
        |> Enum.filter(&(&1 != nil))
        |> Enum.filter(fn(a) -> a.package.id == peme end)
      end)


    benefit_packages2 =
      benefit_packages2
      |> List.flatten()
      |> List.first()

    if not is_nil(benefit_packages2) do
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

          if not is_nil(product_benefit) do
            render(
              conn,
              "show_peme.html",
              changeset: changeset,
              authorization: authorization,
              member: member,
              member_product: member_product,
              product: product,
              product_benefit: product_benefit,
              benefit: benefit,
              benefit_package: benefit_packages2,
              package: package
            )
          else
            conn
            |> put_flash(
              :error,
              "Invalid authorization data. Member has no ACU product benefit to avail"
            )
            |> redirect(to: "/authorizations")
          end
      else
        conn
          |> put_flash(:error, "Not covered from any of packages")
          |> redirect(to: "/authorizations")
      end
    end


  def show_acu(conn, authorization) do
    changeset = Authorization.changeset(authorization)
    member = MemberContext.get_a_member!(authorization.member_id)

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

    # _product_benefit_limit = ProductContext.get_a_product_benefit_limit(product_benefit.id)

    if not is_nil(product_benefit) do
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

      rnb =
        if benefit.acu_type == "Executive" and benefit.acu_coverage == "Inpatient" do
          AuthorizationContext.get_rnb_by_coverage(product, authorization.coverage.id)
        else
          nil
        end

      rnb_hierarchy =
        if benefit.acu_type == "Executive" and benefit.acu_coverage == "Inpatient" do
          if rnb.room_and_board == "Peso Based" do
            nil
          else
            RoomContext.get_a_room(rnb.room_type).hierarchy
          end
        else
          nil
        end

      facility_rooms =
        if benefit.acu_type == "Executive" and benefit.acu_coverage == "Inpatient" do
          FacilityContext.list_all_facility_rooms(authorization.facility_id)
        else
          nil
        end

      render(
        conn,
        "show_acu.html",
        changeset: changeset,
        authorization: authorization,
        member: member,
        member_product: member_product,
        product: product,
        product_benefit: product_benefit,
        benefit: benefit,
        benefit_package: benefit_package,
        package: package,
        rnb: rnb,
        rnb_hierarchy: rnb_hierarchy,
        facility_rooms: facility_rooms
      )
    else
      conn
      |> put_flash(
        :error,
        "Invalid authorization data. Member has no ACU product benefit to avail"
      )
      |> redirect(to: "/authorizations")
    end
  end

  def show_laboratory(conn, authorization) do
    changeset = Authorization.changeset(authorization)

    authorization_procedures =
      AuthorizationContext.get_all_authorization_procedure_diagnosis(authorization.id)

    authorization_diagnosis =
      AuthorizationContext.get_all_authorization_procedure_diagnosis(authorization.id)

    special_approval = DropdownContext.get_all_special_approval()
    diagnoses = DiagnosisContext.get_all_diagnosis()

    practitioners =
      PractitionerContext.get_all_practitioners_by_facility_id_emergency(authorization.facility_id)

    specializations =
      PractitionerContext.filter_practitioner_specialization_emergency(authorization.facility_id)

    member = MemberContext.get_a_member!(authorization.member_id)
    procedures = ProcedureContext.get_payor_procedure_by_facility(authorization.facility_id)
    ruvs = RUVContext.get_ruvs()
    facility_contacts = FacilityContext.get_all_facility_contacts(authorization.facility_id)

    render(
      conn,
      "show_laboratory.html",
      changeset: changeset,
      procedures: procedures,
      special_approval: special_approval,
      diagnoses: diagnoses,
      authorization_procedures: authorization_procedures,
      authorization_diagnosis: authorization_diagnosis,
      authorization: authorization,
      practitioners: practitioners,
      member: member,
      ruvs: ruvs,
      facility_contacts: facility_contacts,
      specializations: specializations
    )
  end

  def validate_member_info(conn, %{"authorization" => authorization_params}) do
    member =
      authorization_params
      |> AuthorizationContext.validate_member_info()

    case member do
      {:not_exists} ->
        conn
        |> put_flash(:error, "Invalid member details.")
        |> redirect(to: "/authorizations/new")

      {:not_active} ->
        conn
        |> put_flash(
          :error,
          "Member is not Active. Only active members are allowed to request LOA."
        )
        |> redirect(to: "/authorizations/new")

      _ ->
        changeset = Authorization.changeset(%Authorization{})
        conn
        |> render("step1.html", changeset: changeset, modal_open: true, members: member)
    end
  end

  def select_member(conn, %{"authorization" => authorization_params}) do
    member_id = authorization_params["member_id"]
    user_id = conn.assigns.current_user.id

    with false <- member_id == "",
         %Member{} = _member <- MemberContext.get_active_member_by_id(member_id),
         {:ok, authorization} <-
           AuthorizationContext.create_authorization(user_id, %{"member_id" => member_id}) do
             #insert_log(conn, authorization.id, "")
      conn
      |> put_flash(:info, "Member info is valid.")
      |> redirect(to: "/authorizations/#{authorization.id}/setup?step=2")
    else
      nil ->
        conn
        |> put_flash(
          :error,
          "Member is not Active. Only active members are allowed to request LOA."
        )
        |> redirect(to: "/authorizations/new")

      true ->
        conn
        |> put_flash(:error, "Please select a member.")
        |> redirect(to: "/authorizations/new")

      {:error, changeset} ->
        conn
        |> render("step1.html", changeset: changeset)
    end
  end

  def validate_card(conn, %{"authorization" => authorization_params}) do
    user_id = conn.assigns.current_user.id

    with {true, member} <- AuthorizationContext.validate_card(authorization_params, conn.scheme),
         {:ok, authorization} <-
           AuthorizationContext.create_authorization(user_id, %{"member_id" => member.id}) do
      conn
      |> put_flash(:info, "Card details is valid.")
      |> redirect(to: "/authorizations/#{authorization.id}/setup?step=2")
    else
      {:invalid_details} ->
        conn
        |> put_flash(:error, "Invalid card details.")
        |> redirect(to: "/authorizations/new")

      {:not_active} ->
        conn
        |> put_flash(
          :error,
          "Member is not Active. Only active members are allowed to request LOA."
        )
        |> redirect(to: "/authorizations/new")

      {:api_address_not_exists} ->
        conn
        |> put_flash(:error, "API address does not exists")
        |> redirect(to: "/authorizations/new")

      {:error_connecting_api, response} ->
        conn
        |> put_flash(:error, response)
        |> redirect(to: "/authorizations/new")

      {:unable_to_login, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: "/authorizations/new")

      {:error, changeset} ->
        conn
        |> render("step1.html", changeset: changeset)
    end
  end

  def setup(conn, %{"id" => authorization_id, "step" => step}) do
    authorization = AuthorizationContext.get_authorization_by_id(authorization_id)

    if is_nil(authorization) do
      authorizations = AuthorizationContext.list_authorizations()

      conn
      |> render("index.html", authorizations: authorizations)
    else
      if authorization.step == 5 do
        conn
        |> put_flash(:error, "You are not allowed to go back to creation steps")
        |> redirect(to: authorization_path(conn, :index))
      else
        goto_step(step, conn, authorization)
      end
    end
  end

  defp goto_step(step, conn, authorization) do
    case step do
      "1" ->
        step1(conn, authorization)

      "2" ->
        step2(conn, authorization)

      "3" ->
        step3(conn, authorization)

      "4" ->
          select_coverage(conn, authorization)
      _ ->
        conn
        |> put_flash(:error, "Invalid step!")
        |> redirect(to: authorization_path(conn, :index))
    end
  end

  defp select_coverage(conn, authorization) do
    coverage =
      authorization.coverage_id
      |> CoverageContext.get_coverage()

    case coverage.name do
      "OP Consult" ->
        step4_op_consult(conn, authorization)

        # step4_consult(conn, authorization)
      "OP Laboratory" ->
        step4_op_laboratory(conn, authorization)

      "Emergency" ->
        step4_emergency(conn, authorization)

      "ACU" ->
        step4_acu(conn, authorization)

      "Inpatient" ->
        step4_inpatient(conn, authorization)

      _ ->
        conn
        |> put_flash(:error, "Invalid Coverage!")
        |> redirect(to: "/authorizations/#{authorization.id}/setup?step=3")
    end
  end

  def update_setup(conn, %{
        "id" => authorization_id,
        "step" => step,
        "authorization" => authorization_params
      }) do
    authorization = AuthorizationContext.get_authorization_by_id(authorization_id)

    case step do
      "2" ->
        update_step2(conn, authorization, authorization_params)

      "3" ->
        update_step3(conn, authorization, authorization_params)

      "4" ->
        coverage = CoverageContext.get_coverage(authorization.coverage_id)

        case coverage.name do
          "OP Consult" ->
            insert_log(conn, authorization.id, "created Outpatient Consultation LOA.")
            update_step4_op_consult(conn, authorization, authorization_params)

          "OP Laboratory" ->
            insert_log(conn, authorization.id, "created Outpatient Laboratory LOA.")
            update_step4_op_laboratory(conn, authorization, authorization_params)

          "Emergency" ->
            update_step4_emergency(conn, authorization, authorization_params)

          "ACU" ->
            insert_log(conn, authorization.id, "created Annual Checkup LOA.")
            update_step4_acu(conn, authorization, authorization_params)

          _ ->
            conn
            |> put_flash(:error, "Invalid coverage!")
            |> redirect(to: authorization_path(conn, :index))
        end
    end
  end

  def step1(conn, authorization) do
    render(conn, "step1_edit.html", authorization: authorization)
  end

  def step2(conn, authorization) do
    changeset =
      authorization
      |> Authorization.changeset()

    result_facilities =
      if is_nil(authorization.facility) do
        nil
      else
        [authorization.facility]
      end

    member_facilities =
      authorization.member_id
      |> FacilityContext.get_facility_by_member_id()

    facilities =
      FacilityContext.get_all_completed_facility()

    facility_types =
      DropdownContext.get_all_facility_type()

    conn
    |> render(
      "step2.html",
      changeset: changeset,
      authorization: authorization,
      result_facilities: Poison.encode!(result_facilities),
      facilities: Poison.encode!(facilities),
      member_facilities: Poison.encode!(member_facilities),
      facility_types: facility_types
    )
  end

  def setup(conn, %{"id" => authorization_id, "search" => search_params}) do

    search_values =
      search_params
      |> Map.values()

    authorization =
      authorization_id
      |> AuthorizationContext.get_authorization_by_id()

    changeset =
      authorization
      |> Authorization.changeset()

    facilities =
      FacilityContext.get_all_completed_facility()

    member_facilities =
      authorization.member_id
      |> FacilityContext.get_facility_by_member_id()

    facility_types =
      DropdownContext.get_all_facility_type()

    if Enum.any?(search_values, fn(val) -> val != "" end) do

      if String.contains?(search_params["code"], "|") do
        facility =
          search_params["code"]
          |> String.split("|")

        search_params =
          search_params
          |> Map.put("code", String.trim(List.first(facility)))
      end

      result_facilities =
        search_params
        |> FacilityContext.search_facilities()

      conn
      |> render(
        "step2.html",
        changeset: changeset,
        authorization: authorization,
        result_facilities: Poison.encode!(result_facilities),
        facilities: Poison.encode!(facilities),
        member_facilities: Poison.encode!(member_facilities),
        facility_types: facility_types
      )
    else
      result_facilities =
        if is_nil(authorization.facility) do
          nil
        else
          [authorization.facility]
        end

      conn
      |> put_flash(
        :error,
        "Please enter at least one search criteria."
      )
      |> render(
        "step2.html",
        changeset: changeset,
        authorization: authorization,
        result_facilities: Poison.encode!(result_facilities),
        facilities: Poison.encode!(facilities),
        member_facilities: Poison.encode!(member_facilities),
        facility_types: facility_types
      )
    end

  end

  def setup(conn, _params) do
    conn
    |> put_flash(:error, "Page not found!")
    |> redirect(to: authorization_path(conn, :index))
  end

  def step3(conn, authorization) do
    coverage = AuthorizationContext.load_valid_coverages(authorization.member_id)
    changeset = Authorization.changeset(authorization)
    # coverage = CoverageContext.get_all_coverages
    facility = FacilityContext.get_facility!(authorization.facility_id)

    render(
      conn,
      "step3.html",
      changeset: changeset,
      authorization: authorization,
      coverage: coverage,
      facility: facility
    )
  end

  def step4_consult(conn, authorization) do
    changeset = Authorization.changeset(authorization)
    special_approval = DropdownContext.get_all_special_approval()
    diagnoses = DiagnosisContext.get_all_diagnoses()

    practitioners =
      PractitionerContext.get_all_practitioners_by_facility_id(authorization.facility_id)

    member = MemberContext.get_a_member!(authorization.member_id)

    render(
      conn,
      "step4_consult.html",
      changeset: changeset,
      special_approval: special_approval,
      diagnoses: diagnoses,
      authorization: authorization,
      practitioners: practitioners,
      member: member
    )
  end

  def step4_op_laboratory(conn, authorization) do
    changeset = Authorization.changeset(authorization)

    authorization_procedures =
      AuthorizationContext.get_all_authorization_procedure_diagnosis(authorization.id)

    authorization_diagnosis =
      AuthorizationContext.get_all_authorization_procedure_diagnosis(authorization.id)

    special_approval = DropdownContext.get_all_special_approval()
    diagnoses = DiagnosisContext.get_all_diagnosis()

    practitioners =
      PractitionerContext.get_all_practitioners_by_facility_id_emergency(authorization.facility_id)

    specializations =
      PractitionerContext.filter_practitioner_specialization_emergency(authorization.facility_id)

    member = MemberContext.get_a_member!(authorization.member_id)
    procedures = ProcedureContext.get_payor_procedure_by_facility(authorization.facility_id)
    ruvs = RUVContext.get_ruvs()
    facility_contacts = FacilityContext.get_all_facility_contacts(authorization.facility_id)
    apds = AuthorizationContext.apds(authorization)
    render(
      conn,
      "step4_laboratory.html",
      changeset: changeset,
      procedures: procedures,
      special_approval: special_approval,
      diagnoses: diagnoses,
      authorization_procedures: authorization_procedures,
      authorization_diagnosis: authorization_diagnosis,
      authorization: authorization,
      practitioners: practitioners,
      member: member,
      ruvs: ruvs,
      facility_contacts: facility_contacts,
      specializations: specializations,
      apds: apds,
      user: conn.assigns.current_user
    )
  end

  def step4_emergency(conn, authorization) do
    changeset = Authorization.changeset(authorization)

    authorization_procedures =
      AuthorizationContext.get_all_authorization_procedure_diagnosis(authorization.id)

    authorization_diagnosis =
      AuthorizationContext.get_all_authorization_procedure_diagnosis(authorization.id)

    special_approval = DropdownContext.get_all_special_approval()
    diagnoses = DiagnosisContext.get_all_diagnosis()

    practitioners =
      PractitionerContext.get_all_practitioners_by_facility_id_emergency(authorization.facility_id)

    specializations =
      PractitionerContext.filter_practitioner_specialization_emergency(authorization.facility_id)

    member = MemberContext.get_a_member!(authorization.member_id)
    procedures = ProcedureContext.get_payor_procedure_by_facility(authorization.facility_id)
    ruvs = RUVContext.get_ruvs()
    facility_contacts = FacilityContext.get_all_facility_contacts(authorization.facility_id)
    apds = AuthorizationContext.apds(authorization)
    render(
      conn,
      "step4_emergency.html",
      changeset: changeset,
      procedures: procedures,
      special_approval: special_approval,
      diagnoses: diagnoses,
      authorization_procedures: authorization_procedures,
      authorization_diagnosis: authorization_diagnosis,
      authorization: authorization,
      practitioners: practitioners,
      member: member,
      ruvs: ruvs,
      facility_contacts: facility_contacts,
      specializations: specializations,
      apds: apds,
      user: conn.assigns.current_user
    )
  end

  def step4_acu(conn, authorization) do
    with member = %Member{} <- MemberContext.get_a_member!(authorization.member_id),
         {:ok, mp} <- get_member_products(member),
         {:ok, mp} <- get_member_product(mp, authorization.coverage),
         {:ok, product} <- get_acu_product(mp.account_product),
         {:ok, pb} <- validate_member_benefit(member, mp),
         {:ok, bp} <- validate_benefit_package(member, mp)
    do

      changeset = Authorization.changeset(authorization)
      benefit = pb.benefit
      benefit_package = List.first(bp)
      package = benefit_package.package
      rnb = get_rnb(benefit.acu_type, benefit.acu_coverage, product, authorization.coverage)
      rnb_hierarchy = get_rnb_hierarchy(benefit.acu_type, benefit.acu_coverage, rnb)
      facility_rooms = get_acu_facility_room(benefit.acu_type, benefit.acu_coverage, authorization)

      render(
        conn,
        "step4_acu.html",
        changeset: changeset,
        authorization: authorization,
        member: member,
        member_product: mp,
        product: product,
        product_benefit: pb,
        benefit: benefit,
        benefit_package: benefit_package,
        package: package,
        rnb: rnb,
        rnb_hierarchy: rnb_hierarchy,
        facility_rooms: facility_rooms
      )
    else
      _ ->
        conn
        |> put_flash(:error, "Member is not eligible to avail ACU")
        |> redirect(to: "/authorizations")
    end
  end

  defp get_member_products(member) do
    mp =
      for member_product <- member.products do
        member_product
      end

    mp =
      mp
      |> Enum.uniq()
      |> List.delete(nil)
      |> List.flatten()

    is_list?(is_list(mp), mp)
  end

  defp is_list?(true, mp), do: {:ok, mp}
  defp is_list?(false, _), do: {:invalid, "Member has no member products"}

  defp get_member_product(mp, nil), do: {:invalid, "Invalid authorization"}
  defp get_member_product(mp, cov) do
    validate_member_product(
      AuthorizationContext.get_member_product_with_coverage_and_tier(mp, cov.id)
    )
  end

  defp validate_member_product(nil), do: {:invalid, "Member is not eligible to avail ACU"}
  defp validate_member_product(mp), do: {:ok, mp}

  defp get_acu_product(nil), do: {:invalid, "Member has no account products"}
  defp get_acu_product(ap), do: {:ok, ap.product}

  defp validate_member_benefit(nil, _), do: {:invalid, "Invalid Member"}
  defp validate_member_benefit(_, nil), do: {:invalid, "Member is not eligible to avail ACU"}
  defp validate_member_benefit(member, mp) do
    validate_member_benefit2(
      MemberContext.get_acu_package_based_on_member(
        member,
        mp
      )
    )
  end

  defp validate_member_benefit2(nil), do: {:invalid, "Member is not eligible to avail ACU"}
  defp validate_member_benefit2(pb), do: {:ok, pb}

  defp validate_benefit_package(nil, _), do: {:invalid, "Invalid Member"}
  defp validate_benefit_package(_, nil), do: {:invalid, "Member is not eligible to avail ACU"}
  defp validate_benefit_package(member, mp) do
    validate_benefit_package2(
      MemberContext.get_acu_package_based_on_member_for_schedule(
        member,
        mp
      )
    )
  end

  defp validate_benefit_package2(nil), do: {:invalid, "Member is not eligible to avail ACU"}
  defp validate_benefit_package2(bp), do: {:ok, bp}

  defp get_rnb(_, _, nil, _), do: nil
  defp get_rnb(_, _, _, nil), do: nil
  defp get_rnb("Executive", "Inpatient", product, coverage), do:
    AuthorizationContext.get_rnb_by_coverage(product, coverage.id)
  defp get_rnb(_, _, _, _), do: nil


  defp get_rnb_hierarchy("Regular", "Outpatient", nil), do: nil
  defp get_rnb_hierarchy("Executive", "Inpatient", nil), do: nil
  defp get_rnb_hierarchy("Executive", "Inpatient", rnb), do: get_rnb_hierarchy2(rnb.room_and_board, rnb)
  defp get_rnb_hierarchy2("Peso Based", _), do: nil
  defp get_rnb_hierarchy2(_, rnb), do: RoomContext.get_a_room(rnb.room_type).hierarchy

  defp get_acu_facility_room(_, _, nil), do: nil
  defp get_acu_facility_room("Executive", "Inpatient", authorization), do:
    FacilityContext.list_all_facility_rooms(authorization.facility_id)
  defp get_acu_facility_room(_, _, _), do: nil

  def step4_inpatient(conn, authorization) do
    changeset = Authorization.changeset(authorization)

    authorization_procedures =
      AuthorizationContext.get_all_authorization_procedure_diagnosis(authorization.id)

    authorization_diagnosis =
      AuthorizationContext.get_all_authorization_procedure_diagnosis(authorization.id)

    authorization_rooms =
      AuthorizationContext.get_all_authorization_rooms(authorization.id)

    special_approval = DropdownContext.get_all_special_approval()
    diagnoses = DiagnosisContext.get_all_diagnosis()

    practitioners =
      PractitionerContext.get_all_practitioners_by_facility_id_inpatient(authorization.facility_id)

    member = MemberContext.get_a_member!(authorization.member_id)

    procedures =
      ProcedureContext.get_emergency_payor_procedure_by_facility(authorization.facility_id)

    ruvs = RUVContext.get_ruvs()
    facility_contacts = FacilityContext.get_all_facility_contacts(authorization.facility_id)

    facility_room_rates = FacilityRoomRateContext.get_all_facility_room_rate(authorization.facility_id)

    render(
      conn,
      "step4_inpatient.html",
      changeset: changeset,
      procedures: procedures,
      special_approval: special_approval,
      diagnoses: diagnoses,
      authorization_procedures: authorization_procedures,
      authorization_diagnosis: authorization_diagnosis,
      authorization: authorization,
      practitioners: practitioners,
      member: member,
      ruvs: ruvs,
      facility_contacts: facility_contacts,
      facility_room_rates: facility_room_rates,
      authorization_rooms: authorization_rooms
    )
  end

  def create_inpatient_room_and_board(conn, authorization_params) do
    authorization = AuthorizationContext.get_authorization_by_id(authorization_params["id"])
    authorization_params = authorization_params["authorization"]
    facility_room_rates = FacilityRoomRateContext.get_all_facility_room_rate(authorization.facility_id)

    admission_time = String.split(authorization_params["admission_time"], ":")
    frr = FacilityRoomRateContext.get_facility_room_rate_by_number(authorization_params["room_number"])

    params = %{
      "admission_date" => Ecto.Date.cast!(authorization_params["admission_date"]),
      "admission_time" => Ecto.Time.cast!(%{
        "hour" => Enum.at(admission_time, 0),
        "minute" => Enum.at(admission_time, 1)
      }),
      "facility_room_rate_id" => frr.id,
      "for_isolation" => authorization_params["for_isolation"],
      "authorization_id" => authorization.id,
    }

    unless Enum.all?([authorization_params["transfer_date"] == "", authorization_params["transfer_time"]]) do
      transfer_time = String.split(authorization_params["transfer_time"], ":")
      params = Map.merge(params, %{
        "transfer_date" => Ecto.Date.cast!(authorization_params["transfer_date"]),
        "transfer_time" => Ecto.Time.cast!(%{
          "hour" => Enum.at(transfer_time, 0),
          "minute" => Enum.at(transfer_time, 1)
        })
      })
    end


    if authorization_params["authorization_room_id"] == "" do
      with {:ok, authorization_room} <- AuthorizationContext.create_authorization_room(params) do
        conn
        |> put_flash(:info, "Authorization Room and Board successfully added!")
        |> redirect(to: "/authorizations/#{authorization.id}/setup?step=4")
      else
        {:error, changeset} ->
          raise changeset
      end
    else
      auth_room = AuthorizationContext.get_authorization_room(authorization_params["authorization_room_id"])
      with {:ok, authorization_room} <- AuthorizationContext.update_authorization_room(auth_room, params) do
        conn
        |> put_flash(:info, "Authorization Room and Board successfully updated!")
        |> redirect(to: "/authorizations/#{authorization.id}/setup?step=4")
      else
        {:error, changeset} ->
          raise changeset
      end
    end
  end

  def update_step2(conn, authorization, authorization_params) do
    result_facilities =
      if not is_nil(authorization.facility) do
        [authorization.facility]
      else
        nil
      end

    facilities =
      FacilityContext.get_all_completed_facility()

    member_facilities =
      authorization.member_id
      |>  FacilityContext.get_facility_by_member_id()

    facility_types =
      DropdownContext.get_all_facility_type()

    with false <- authorization_params["facility_id"] == "" || authorization_params == %{},
         {:ok, authorization} <-
           AuthorizationContext.update_authorization_step2(
             conn.assigns.current_user.id,
             authorization_params,
             authorization
           )
    do

      conn
      |> put_flash(:info, "Successfully selected facility.")
      |> redirect(to: "/authorizations/#{authorization.id}/setup?step=3")

    else
      true ->
        changeset = Authorization.changeset(authorization)

        conn
        |> put_flash(:error, "Please select a facility.")
        |> render(
          "step2.html",
          changeset: changeset,
          authorization: authorization,
          result_facilities: Poison.encode!(result_facilities),
          facilities: Poison.encode!(facilities),
          member_facilities: Poison.encode!(member_facilities),
          facility_types: facility_types
        )

      {:error, _changeset} ->
        changeset = Authorization.changeset(authorization)

      conn
      |> put_flash(:error, "Error encountered while selecting facility.")
      |> render(
        "step2.html",
        changeset: changeset,
        authorization: authorization,
        result_facilities: Poison.encode!(result_facilities),
        facilities: Poison.encode!(facilities),
        member_facilities: Poison.encode!(member_facilities),
        facility_types: facility_types
      )
    end
  end

  def update_step3(conn, authorization, authorization_params) do
    old_coverage = authorization.coverage_id

    with {:ok, authorization} <-
           AuthorizationContext.update_authorization_step3(
             authorization,
             authorization_params,
             conn.assigns.current_user.id
           ) do
      new_coverage = authorization.coverage_id

      if old_coverage != new_coverage do
        AuthorizationContext.delete_authorization_step_4_setup(authorization.id)
      end

      conn
      |> redirect(to: "/authorizations/#{authorization.id}/setup?step=4")
    else
      {:invalid_coverage, error} ->
        coverage = AuthorizationContext.load_valid_coverages(authorization.member_id)
        facility = FacilityContext.get_facility!(authorization.facility_id)
        changeset = Authorization.changeset(authorization)

        conn
        |> put_flash(:error, error)
        |> render(
          "step3.html",
          changeset: changeset,
          authorization: authorization,
          coverage: coverage,
          facility: facility
        )

      {:error, changeset} ->
        coverage = AuthorizationContext.load_valid_coverages(authorization.member_id)
        # coverage = AuthorizationContext.get_member_benefit_coverage(authorization.member_id)
        facility = FacilityContext.get_facility!(authorization.facility_id)

        conn
        |> render(
          "step3.html",
          changeset: changeset,
          authorization: authorization,
          coverage: coverage,
          facility: facility
        )
    end
  end

  def update_step4_op_consult(conn, authorization, authorization_params) do
    user_id = conn.assigns.current_user.id
    params = consult_params(authorization_params)

    with {:ok, authorization2} <- AuthorizationContext.modify_loa(authorization, params, user_id)
    do
      params = Map.put_new(params, "authorization_id", authorization2.id)
      AuthorizationContext.create_authorization_diagnosis(params, user_id)
      AuthorizationContext.create_authorization_practitioner_specialization(params, user_id)
      AuthorizationContext.create_authorization_amount(params, user_id)

      authorizations = AuthorizationContext.get_authorization_by_id(authorization.id)
      test =  authorizations.authorization_diagnosis |> List.first()
      if is_nil(test.product_benefit_id) && not is_nil(test.product_exclusion_id) do
        pec_setup_limit_checker(conn, authorizations, authorization_params, params)
      else
        no_pec_setup_limit_checker(conn, authorizations, authorization_params, params)
      end
    else
      _ ->
      changeset = Authorization.changeset(authorization)
      special_approval = DropdownContext.get_all_special_approval()
      diagnoses = DiagnosisContext.get_all_diagnoses()
      authorization_files = AuthorizationContext.load_authorization_files(authorization.id)

      practitioners =
        PractitionerContext.get_all_practitioners_by_facility_id(authorization.facility_id)

      member = MemberContext.get_a_member!(authorization.member_id)
      specializations = SpecializationContext.get_all_specializations()

      conn
      |> put_flash(:error, "Error in requesting OP Consult LOA.")
      |> render(
        "step4_op_consult.html",
        changeset: changeset,
        special_approval: special_approval,
        diagnoses: diagnoses,
        authorization: authorization,
        practitioners: practitioners,
        specializations: specializations,
        authorization_files: authorization_files,
        member: member
      )
    end
  end

  defp pec_setup_limit_checker(conn, authorizations, authorization_params, params) do
    is_medina = get_authorization_product_used(authorizations).is_medina
    product_base = get_authorization_product_used(authorizations).product_base
    nod = get_authorization_product_used(authorizations).no_outright_denial
    pf_status = DropdownContext.get_dropdown(get_practitioner_facility_status(authorizations).pstatus_id).value
    p_status = get_practitioner_status(authorizations).affiliated
    practitioner_status = if p_status == "Yes" do
      "Affiliated"
    else
      "Non-affiliated"
    end

    authorization_params =
      authorization_params
      |> Map.put("product_base", product_base)
      |> Map.put("isNOD", nod)
      |> Map.put("pf_status", pf_status)
      |> Map.put("p_status", practitioner_status)
      |> Map.put("is_medina", is_medina)

    user_roles = UserContext.get_user!(conn.assigns.current_user.id).roles
    user_limit =
    if is_nil(user_roles) do
      Decimal.new(0)
    else
      user_limit = List.first(user_roles).approval_limit
      Decimal.new(user_limit || 0)
    end

    is_member_pay = authorization_params["isMemberPay"] || nil
    special_approval_amount =  params["special_approval_amount2"] || Decimal.new(0)
    with {:ok} <- AuthorizationContext.pec_check_excess_inner_limit_consult(authorizations) do
      if Decimal.compare(authorizations.authorization_amounts.total_amount, user_limit) == Decimal.new(-1) do
          validate_is_sonny_medina(conn, special_approval_amount, authorizations, authorization_params, is_member_pay)
      else
          set_status_in_authorization(authorizations, authorization_params)
      end
    else
      _ ->
         set_status_in_authorization(authorizations, authorization_params)
    end

    conn
    |> put_flash(:info, "Authorization Successfully Submitted.")
    |> redirect(to: "/authorizations")
  end

  defp insert_to_providerlink(authorization_id, scheme) do
    authorization =
      authorization_id
      |> AuthorizationContext.get_authorization_by_id()

    coverage =
      authorization.coverage.name
      |> String.upcase

    providerlink_params = %{
      payorlink_member_id: authorization.member.id,
      member_last_name: authorization.member.last_name,
      member_first_name: authorization.member.first_name,
      member_gender: authorization.member.gender,
      member_birth_date: authorization.member.birthdate,
      member_card_no: authorization.member.card_no,
      provider: %{
        payorlink_facility_id: authorization.facility.id,
        name: authorization.facility.name,
        code: authorization.facility.code,
      },
      total_amount: Decimal.add(
        authorization.authorization_amounts.payor_covered,
        authorization.authorization_amounts.member_covered
      ),
      payor_pays: authorization.authorization_amounts.payor_covered,
      member_pays: authorization.authorization_amounts.member_covered,
      status: authorization.status,
      loa_number: authorization.number,
      coverage: authorization.coverage.name,
      consultation_date: authorization.admission_datetime,
      valid_until: (
        if is_nil(authorization.approved_datetime) do
          ""
        else
          authorization.approved_datetime
          |> Timex.add(TD.from_days(2))
          |> Ecto.DateTime.cast!
        end
      ),
      issue_date: authorization.approved_datetime,
      origin: "payorlink",
      payorlink_authorization_id: authorization.id,
      request_date: authorization.requested_datetime
    }

    providerlink_params =
      case coverage do
        "OP CONSULT" ->
          diagnosis =
            authorization.authorization_diagnosis
            |> Enum.into(
              [],
              fn(ad) ->
                %{
                  payorlink_diagnosis_id: ad.diagnosis.id,
                  diagnosis_code: ad.diagnosis.code,
                  diagnosis_description: ad.diagnosis.description
                }
              end
            )

          doctor =
            authorization.authorization_practitioner_specializations
            |> Enum.into(
              [],
              fn(ap) ->
                %{
                  payorlink_practitioner_id: ap.practitioner_specialization.practitioner.id,
                  first_name: ap.practitioner_specialization.practitioner.first_name,
                  middle_name: ap.practitioner_specialization.practitioner.middle_name,
                  last_name: ap.practitioner_specialization.practitioner.last_name,
                  extension: ap.practitioner_specialization.practitioner.suffix,
                  prc_number: ap.practitioner_specialization.practitioner.prc_no,
                  status: ap.practitioner_specialization.practitioner.status,
                  affiliated: (
                    if ap.practitioner_specialization.practitioner.affiliated |> String.upcase == "YES"
                    do "true"
                    else "false" end),
                  code: ap.practitioner_specialization.practitioner.code,
                  specialization: ap.practitioner_specialization.specialization.name
                }
              end
            )

          providerlink_params
          |> Map.put(:diagnosis, diagnosis)
          |> Map.put(:doctor, doctor)
        "ACU" ->
          providerlink_params
      end

    providerlink_params
    |> AuthorizationContext.insert_authorization_to_providerlink(scheme)
  end

  defp no_pec_setup_limit_checker(conn, authorizations, authorization_params, params) do
    is_medina = get_authorization_product_used(authorizations).is_medina
    product_base = get_authorization_product_used(authorizations).product_base
    nod = get_authorization_product_used(authorizations).no_outright_denial
    pf_status = DropdownContext.get_dropdown(get_practitioner_facility_status(authorizations).pstatus_id).value
    p_status = get_practitioner_status(authorizations).affiliated
    practitioner_status = if p_status == "Yes" do
      "Affiliated"
    else
      "Non-affiliated"
    end

    authorization_params =
      authorization_params
      |> Map.put("product_base", product_base)
      |> Map.put("isNOD", nod)
      |> Map.put("pf_status", pf_status)
      |> Map.put("p_status", practitioner_status)
      |> Map.put("is_medina", is_medina)

    user_roles = UserContext.get_user!(conn.assigns.current_user.id).roles
    user_limit =
    if is_nil(user_roles) do
      Decimal.new(0)
    else
      user_limit = List.first(user_roles).approval_limit
      Decimal.new(user_limit || 0)
    end

    is_member_pay = authorization_params["isMemberPay"] || nil
    special_approval_amount =  params["special_approval_amount2"] || Decimal.new(0)
    with {:ok} <- AuthorizationContext.check_excess_limits_consult(authorizations) do
      if Decimal.compare(authorizations.authorization_amounts.total_amount, user_limit) == Decimal.new(-1) do
          validate_is_sonny_medina(conn, special_approval_amount, authorizations, authorization_params, is_member_pay)
      else
          set_status_in_authorization(authorizations, authorization_params)
      end
    else
      _ ->
         set_status_in_authorization(authorizations, authorization_params)
    end

    authorizations.id
    |> insert_to_providerlink(conn.scheme)

    conn
    |> put_flash(:info, "Authorization Successfully Submitted.")
    |> redirect(to: "/authorizations")
  end

  defp validate_is_sonny_medina(conn, special_approval_amount, authorizations, authorization_params, is_member_pay) do
    if authorization_params["is_medina"] == true do
      if Decimal.to_float(Decimal.new(special_approval_amount)) > Decimal.to_float(Decimal.new(0)) do
        set_status_in_authorization(authorizations, authorization_params)
      else
        set_status_in_authorization_without_special_approval(conn,
          authorizations, authorization_params, is_member_pay)
      end
    else
      if Decimal.to_float(Decimal.new(special_approval_amount)) > Decimal.to_float(Decimal.new(0)) do
        update_for_approval_authorization(authorizations, authorization_params)
      else
        if is_nil(is_member_pay) do
          update_for_approval_authorization(authorizations, authorization_params)
        else
          if Decimal.to_float(Decimal.new(authorization_params["member_pays"])) > Decimal.to_float(Decimal.new(0)) do
            update_for_approval_authorization(authorizations, authorization_params)
          else
            update_for_approval_authorization(authorizations, authorization_params)
          end
        end
      end
    end
  end

  defp get_practitioner_facility_status(authorization) do
    aps = authorization.authorization_practitioner_specializations |> List.first()
    practitioner_facilities = aps.practitioner_specialization.practitioner.practitioner_facilities
    pf = for practitioner_facility <- practitioner_facilities do
      practitioner_facility
    end
    Enum.find(pf, &(&1.facility_id == authorization.facility_id))
  end

  defp get_practitioner_status(authorization) do
    aps = authorization.authorization_practitioner_specializations |> List.first()
    practitioner = aps.practitioner_specialization.practitioner
  end

  defp get_authorization_product_used(authorization) do
    ad = authorization.authorization_diagnosis |> List.first()
    if is_nil(ad.member_product) do
      %{
        product_base: nil,
        no_outright_denial: nil,
        is_medina: nil
      }
    else
      ad.member_product.account_product.product
    end
  end

  defp set_status_in_authorization_without_special_approval(conn, authorizations, authorization_params, is_member_pay) do
    if Decimal.to_float(Decimal.new(authorization_params["payor_pays"])) == Decimal.to_float(Decimal.new(0)) do
      if authorization_params["product_base"] == "Exclusion-based" do
        if authorization_params["isNOD"] != true do
          update_disapproved_authorization(authorizations, authorization_params)
        else
          update_for_approval_authorization(authorizations, authorization_params)
        end
      else
        update_disapproved_authorization(authorizations, authorization_params)
      end
    else
      if is_nil(is_member_pay) do
        update_for_approval_authorization(authorizations, authorization_params)
      else
        check_loa_is_nod_per_product_base(authorizations, authorization_params, conn)
      end
    end
  end

  defp check_loa_is_nod_per_product_base(authorizations, authorization_params, conn) do
    if authorization_params["product_base"] == "Exclusion-based" do
      # if selected ICD is generally excluded and the product has a set up of ‘No outright denial’
      # for Exclusion Based Only
      check_loa_exclusion_based(authorizations, authorization_params, conn)
    else
      # Benefit Based
      check_loa_practitioner_status(authorizations, authorization_params, conn)
    end
  end

  defp check_loa_exclusion_based(authorizations, authorization_params, conn) do
    if authorization_params["isNOD"] == true do
      update_for_approval_authorization(authorizations, authorization_params)
    else
      # check practitioner and facility affiliation status
      check_loa_practitioner_status(authorizations, authorization_params, conn)
    end
  end

  defp check_loa_practitioner_status(authorizations, authorization_params, conn) do
    # if practitioner status is non affiliated
    if authorization_params["p_status"] == "Non-affiliated" do
      set_isNonAffiliated_practitioner_status(authorizations, authorization_params, conn)
    else
      set_isAffiliated_practitioner_status(authorizations, authorization_params, conn)
    end
  end

  def set_isNonAffiliated_practitioner_status(authorizations, authorization_params, conn) do
    # If one of the conditions in For approval rules are met and product is tagged as outright denial.
    if authorization_params["isNOD"] != true do
      update_disapproved_authorization(authorizations, authorization_params)
    else
      update_for_approval_authorization(authorizations, authorization_params)
    end
  end

  def set_isAffiliated_practitioner_status(authorizations, authorization_params, conn) do
      # if practitioner is facility non affiliated or disaffiliated
    if authorization_params["pf_status"] == "Non-affiliated" or authorization_params["pf_status"] == "Disaffiliated" do
      set_isNonAffiliated_facility_status(authorizations, authorization_params, conn)
    else
      set_isAffiliated_facility_status(authorizations, authorization_params, conn)
    end
  end

  defp set_isNonAffiliated_facility_status(authorizations, authorization_params, conn) do
    # If one of the conditions in For approval rules are met and product is tagged as outright denial.
    if authorization_params["isNOD"] != true do
      update_disapproved_authorization(authorizations, authorization_params)
    else
      update_for_approval_authorization(authorizations, authorization_params)
    end
  end

  defp set_isAffiliated_facility_status(authorizations, authorization_params, conn) do
    if Decimal.to_float(Decimal.new(authorization_params["member_pays"])) > Decimal.to_float(Decimal.new(0)) do
      if authorization_params["isNOD"] != true do
        update_disapproved_authorization(authorizations, authorization_params)
      else
        update_for_approval_authorization(authorizations, authorization_params)
      end
    else
      # set loa status to approve
      set_authorizations_approved_status(authorizations, authorization_params, conn)
    end
  end

  defp set_authorizations_approved_status(authorizations, authorization_params, conn) do
    update_approved_authorization(authorizations, authorization_params, conn.assigns.current_user.id)
  end

  defp set_status_in_authorization(authorizations, authorization_params) do
    if Decimal.to_float(Decimal.new(authorization_params["payor_pays"])) == Decimal.to_float(Decimal.new(0)) do
      if authorization_params["is_medina"] == true do
        update_disapproved_authorization(authorizations, authorization_params)
      else
        if authorization_params["isNOD"] != true do
          update_disapproved_authorization(authorizations, authorization_params)
        else
          update_for_approval_authorization(authorizations, authorization_params)
        end
      end
    else
      # If one of the conditions in For approval rules are met and product is tagged as outright denial.
      if authorization_params["is_medina"] == true do
        if authorization_params["isNOD"] != true do
          update_disapproved_authorization(authorizations, authorization_params)
        else
          update_for_approval_authorization(authorizations, authorization_params)
        end
      else
        update_for_approval_authorization(authorizations, authorization_params)
      end
    end
  end

  defp update_for_approval_authorization(authorizations, authorization_params) do
    AuthorizationContext.update_authorization(authorizations.id, %{
        "origin" => "payorlink",
        "status" => "For Approval",
        "step" => 5
    } |> Map.merge(authorization_params))
  end

  defp update_disapproved_authorization(authorizations, authorization_params) do
    AuthorizationContext.update_authorization(authorizations.id, %{
        "origin" => "payorlink",
        "status" => "Disapproved",
        "step" => 5
    } |> Map.merge(authorization_params))
  end

  defp update_approved_authorization(authorizations, authorization_params, user_id) do
    AuthorizationContext.update_approve_authorization(authorizations.id, %{
      "origin" => "payorlink",
      "status" => "Approved",
      "step" => 5,
      "approved_by_id" => user_id,
      "approved_datetime" => Ecto.DateTime.from_erl(:erlang.localtime)
    } |> Map.merge(authorization_params))
  end

  defp update_approver_authorization_amount(authorizations, user_id) do
    AuthorizationContext.update_authorization_amount(authorizations.id, %{
      "origin" => "payorlink",
      "approved_by_id" => user_id,
      "approved_datetime" => Ecto.DateTime.from_erl(:erlang.localtime)
    })
  end

  defp consult_params(authorization_params) do
    valid_until =
      ((:erlang.universaltime |> :calendar.datetime_to_gregorian_seconds) + 777_600)
    valid_until =
      valid_until
      |> :calendar.gregorian_seconds_to_datetime
      |> Ecto.DateTime.cast!
    params = %{
        "chief_complaint" => authorization_params["chief_complaint"],
        "chief_complaint_others" => authorization_params["chief_complaint_others"],
        "consultation_fee" => authorization_params["consultation_fee"],
        "consultation_type" => authorization_params["consultation_type"],
        "copayment" => Decimal.new(0),
        "coinsurance" => nil,
        "coinsurance_percentage" => nil,
        "pre_existing_percentage" => nil,
        "covered_after_percentage" => nil,
        "pre_existing_amount" => authorization_params["pre_existing_amount"],
        "diagnosis_id" => authorization_params["diagnosis_id"],
        "member_covered" => authorization_params["member_pays"],
        "member_pay" => authorization_params["member_pays"],
        "member_vat_amount" => authorization_params["member_vat_amount"],
        "member_portion" => authorization_params["member_portion"],
        "special_approval_amount" => authorization_params["special_approval_amount2"],
        "special_approval_portion" => authorization_params["special_approval_portion"],
        "special_approval_vat_amount" => authorization_params["special_approval_vat_amount"],
        "special_approval_id" => authorization_params["special_approval_id"],
        "payor_covered" => authorization_params["payor_pays"],
        "payor_pay" => authorization_params["payor_pays"],
        "payor_vat_amount" => authorization_params["payor_vat_amount"],
        "payor_portion" => authorization_params["payor_portion"],
        "company_covered" => Decimal.new(0),
        "practitioner_specialization_id" => authorization_params["practitioner_specialization_id"],
        "risk_share_type" => nil,
        "admission_datetime" => Ecto.DateTime.from_erl(:erlang.localtime),
        "member_product_id" => authorization_params["member_product_id"],
        "product_benefit_id" => authorization_params["product_benefit_id"],
        "product_exclusion_id" => authorization_params["product_exclusion_id"],
        "total_amount" => authorization_params["total_amount"],
        "internal_remarks" => authorization_params["internal_remarks"],
        "valid_until" => valid_until
      }
  end

  #  END

  defp authorization_params(authorization_params) do
    valid_until =
      ((:erlang.universaltime |> :calendar.datetime_to_gregorian_seconds) + 172_800)
    valid_until =
      valid_until
      |> :calendar.gregorian_seconds_to_datetime
      |> Ecto.DateTime.cast!
    {:ok, admission_datetime} = UtilityContext.birth_date_transform(authorization_params["admission_datetime"])
    {:ok, discharge_datetime} = UtilityContext.birth_date_transform(authorization_params["discharge_datetime"])
    if authorization_params["date_issued"] != "" and not is_nil(authorization_params["date_issued"]) do
      {:ok, date_issued} = UtilityContext.birth_date_transform(authorization_params["date_issued"])
      authorization_params =
      authorization_params
      |> Map.put(
        "date_issued",
        date_issued
      )
    end

    authorization_params =
      authorization_params
      |> Map.put(
        "admission_datetime",
        admission_datetime
        |> Ecto.DateTime.from_date()
      )
      |> Map.put(
        "discharge_datetime",
        discharge_datetime
        |> Ecto.DateTime.from_date()
      )
      |> Map.put(
        "valid_until", valid_until
      )
      |> Map.put(
        "senior_discount",
        String.replace(authorization_params["senior_discount"], ",", "")
        )
      |> Map.put(
        "pwd_discount",
        String.replace(authorization_params["pwd_discount"], ",", "")
        )
    if authorization_params["chief_complaint"] == "Others" and authorization_params["chief_complaint_others"] == "" do
      authorization_params =
      authorization_params
      |> Map.put(
        "chief_complaint",
        ""
      )
    end
    authorization_params
  end

  def update_step4_op_laboratory(conn, authorization, authorization_params) do
    authorization_params = authorization_params(authorization_params)
    user_roles = UserContext.get_user!(conn.assigns.current_user.id).roles

    user_limit =
      if is_nil(user_roles) do
        Decimal.new(0)
      else
        user_limit = List.first(user_roles).approval_limit
        Decimal.new(user_limit || 0)
      end

    if authorization_params["sos"] == "submit" do
      cond do
        authorization_params["senior_citizen_id"] != "" and authorization_params["pwd_id"] != "" ->
          with {:ok, member} <- insert_senior(authorization.member.id, authorization_params["senior_citizen_id"]),
            insert_pwd(authorization.member.id, authorization_params["pwd_id"])
          do
            AuthorizationContext.submit_authorization(authorization, authorization_params, conn.assigns.current_user.id)
            if Decimal.compare(authorization.authorization_amounts.total_amount, user_limit) ==
                 Decimal.new(1) do
              AuthorizationContext.update_authorization(
                authorization.id,
                %{"status" => "For Approval", "step" => "5"} |> Map.merge(authorization_params)
              )
            else
              AuthorizationContext.update_approve_authorization(
                authorization.id,
                %{
                  "status" => "Approved",
                  "step" => 5
                }
                |> Map.merge(authorization_params)
              )
            end
              conn
              |> put_flash(:info, "LOA submitted successfully!")
              |> redirect(to: "/authorizations")
          else
            {:already_exist} ->
              conn
              |> put_flash(:error, "PWD/Senior ID already exist.")
              |> redirect(to: "/authorizations/#{authorization.id}/setup?step=4")
          end
        authorization_params["senior_citizen_id"] != "" ->
          with {:ok, member} <- insert_senior(authorization.member.id, authorization_params["senior_citizen_id"]) do
            AuthorizationContext.submit_authorization(authorization, authorization_params, conn.assigns.current_user.id)
            if Decimal.compare(authorization.authorization_amounts.total_amount, user_limit) ==
                 Decimal.new(1) do
              AuthorizationContext.update_authorization(
                authorization.id,
                %{"status" => "For Approval", "step" => "5"} |> Map.merge(authorization_params)
              )
            else
              AuthorizationContext.update_approve_authorization(
                authorization.id,
                %{
                  "status" => "Approved",
                  "step" => 5
                }
                |> Map.merge(authorization_params)
              )
            end
              conn
              |> put_flash(:info, "LOA submitted successfully!")
              |> redirect(to: "/authorizations")
          else
            {:already_exist} ->
              conn
              |> put_flash(:error, "Senior ID already exist.")
              |> redirect(to: "/authorizations/#{authorization.id}/setup?step=4")
          end
        authorization_params["pwd_id"] != "" ->
          with {:ok, member} <- insert_pwd(authorization.member.id, authorization_params["senior_citizen_id"]) do
            AuthorizationContext.submit_authorization(authorization, authorization_params, conn.assigns.current_user.id)
            OPLabValidator.validate_authorization(authorization)
            if Decimal.compare(authorization.authorization_amounts.total_amount, user_limit) ==
                 Decimal.new(1) do
              AuthorizationContext.update_authorization(
                authorization.id,
                %{"status" => "For Approval", "step" => "5"} |> Map.merge(authorization_params)
              )
            else
              AuthorizationContext.update_approve_authorization(
                authorization.id,
                %{
                  "status" => "Approved",
                  "step" => 5
                }
                |> Map.merge(authorization_params)
              )
            end
            conn
            |> put_flash(:info, "LOA submitted successfully!")
            |> redirect(to: "/authorizations")
          else
            {:already_exist} ->
              conn
              |> put_flash(:error, "PWD ID already exist.")
              |> redirect(to: "/authorizations/#{authorization.id}/setup?step=4")
          end
        true ->
          OPLabValidator.validate_authorization(authorization)
          if Decimal.compare(authorization.authorization_amounts.total_amount, user_limit) ==
               Decimal.new(1) do
            AuthorizationContext.update_authorization(
              authorization.id,
              %{"status" => "For Approval", "step" => "5"} |> Map.merge(authorization_params)
            )
          else
            AuthorizationContext.update_approve_authorization(
              authorization.id,
              %{
                "status" => "Approved",
                "step" => 5
              }
              |> Map.merge(authorization_params)
            )
          end
          conn
          |> put_flash(:info, "LOA submitted successfully!")
          |> redirect(to: "/authorizations")
        end
    else
      with {:ok, authorization} <- AuthorizationContext.save_authorization(authorization, authorization_params, conn.assigns.current_user.id) do
        conn
        |> put_flash(:info, "Authorization successfully saved!")
        |> redirect(to: "/authorizations")
      else
        {:error, _reason} ->
          conn
          |> put_flash(:error, "Failed to save authorization.")
          |> redirect(to: "/authorizations/#{authorization.id}/setup?step=4")
      end
    end
  end

  def update_step4_acu(conn, authorization, authorization_params) do
    product_benefit = ProductContext.get_a_product_benefit2(authorization_params["product_benefit_id"])
    params = %{
      authorization_id: authorization.id,
      user_id: conn.assigns.current_user.id,
      member_id: authorization.member_id,
      facility_id: authorization.facility_id,
      coverage_id: authorization.coverage_id,
      room_id: authorization_params["room_id"],
      benefit_package_id: authorization_params["benefit_package_id"],
      admission_date: authorization_params["admission_datetime"],
      discharge_date: authorization_params["discharge_datetime"],
      product_id: authorization_params["product_id"],
      product: product_benefit.product,
      internal_remarks: authorization_params["internal_remarks"],
      valid_until: authorization_params["valid_until"],
      member_product_id: authorization_params["member_product_id"],
      product_benefit_id: authorization_params["product_benefit_id"],
      origin: "payorlink",
      product_benefit: product_benefit
    }

    with {:ok, changeset} <- ACUValidator.request_acu(params) do
      authorization =
        AuthorizationContext.get_authorization_by_id(changeset.changes.authorization_id)

      message =
        if authorization.status == "Approved" do
          "Successfully generated and approved LOA."
        else
          "Successfully saved and generated LOA."
        end

      conn
      |> put_flash(:info, message)
      |> redirect(to: "/authorizations")
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        a = acu_error(authorization)

        conn
        |> put_flash(:error, "Error in requesting ACU LOA.")
        |> render(
          "step4_acu.html",
          changeset: changeset,
          authorization: a.authorization,
          member: a.member,
          member_product: a.member_product,
          product: a.product,
          product_benefit: a.product_benefit,
          benefit: a.benefit,
          benefit_package: a.benefit_package,
          package: a.package,
          rnb: a.rnb,
          rnb_hierarchy: a.rnb_hierarchy,
          facility_rooms: a.facility_rooms
        )

      {:invalid_coverage, error} ->
        changeset = Authorization.changeset(authorization)
        a = acu_error(authorization)

        conn
        |> put_flash(:error, error)
        |> render(
          "step4_acu.html",
          changeset: changeset,
          authorization: authorization,
          member: a.member,
          member_product: a.member_product,
          product: a.product,
          product_benefit: a.product_benefit,
          benefit: a.benefit,
          benefit_package: a.benefit_package,
          package: a.package,
          rnb: a.rnb,
          rnb_hierarchy: a.rnb_hierarchy,
          facility_rooms: a.facility_rooms
        )
    end
  end

  defp acu_error(authorization) do
    member = MemberContext.get_a_member!(authorization.member_id)

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

    # _product_benefit_limit = ProductContext.get_a_product_benefit_limit(product_benefit.id)

    benefit = product_benefit.benefit
    benefit_package = List.first(benefit.benefit_packages)
    package = benefit_package.package

    rnb =
      if benefit.acu_type == "Executive" and benefit.acu_coverage == "Inpatient" do
        AuthorizationContext.get_rnb_by_coverage(product, authorization.coverage.id)
      else
        nil
      end

    rnb_hierarchy =
      if benefit.acu_type == "Executive" and benefit.acu_coverage == "Inpatient" do
        if rnb.room_and_board == "Peso Based" do
          nil
        else
          RoomContext.get_a_room(rnb.room_type).hierarchy
        end
      else
        nil
      end

    facility_rooms =
      if benefit.acu_type == "Executive" and benefit.acu_coverage == "Inpatient" do
        FacilityContext.list_all_facility_rooms(authorization.facility_id)
      else
        nil
      end

    %{
      member: member,
      member_product: member_product,
      product: product,
      product_benefit: product_benefit,
      benefit: benefit,
      benefit_package: benefit_package,
      package: package,
      rnb: rnb,
      rnb_hierarchy: rnb_hierarchy,
      facility_rooms: facility_rooms
    }
  end

  defp create_authorization_procedure(authorization_id, diagnosis_id, procedure_ids, current_user) do
    if is_nil(procedure_ids) do
      params = %{
        "authorization_id" => authorization_id,
        "diagnosis_id" => diagnosis_id,
      }

      _params =
        params
        |> AuthorizationContext.create_authorization_diagnosis_only(current_user.id)
    else
      for {_counter, params} <- procedure_ids do
        amount = Decimal.new(params["amount"])
        aps = AuthorizationContext.get_one_aps_by_ps_id(params["practitioner_id"])
        params = %{
          "authorization_id" => authorization_id,
          "diagnosis_id" => diagnosis_id,
          "payor_procedure_id" => params["procedure_id"],
          "unit" => params["unit"],
          "amount" => Decimal.div(amount, Decimal.new(params["unit"])),
          "authorization_practitioner_specialization_id" => aps.id
        }
        _params =
          params
          |> AuthorizationContext.create_authorization_procedure(current_user.id)
      end
    end
  end

  # Consult API
  def get_pec(conn, %{"id" => authorization_id, "params" => diagnosis_id}) do
    authorization = AuthorizationContext.get_authorization_by_id(authorization_id)
    member = MemberContext.get_member!(authorization.member_id)

    member_product =
      for member_product <- member.products do
        member_product.account_product.product
      end

    product = List.first(member_product)

    pec = ProductContext.get_pec(product.id, diagnosis_id, member.id)
    json(conn, Poison.encode!(pec))
  end

  def get_consultation_fee(conn, %{"id" => authorization_id, "params" => practitioner_id}) do
    authorization = AuthorizationContext.get_authorization_by_id(authorization_id)

    consultation_fee =
      PractitionerContext.get_consultation_fee(practitioner_id, authorization.facility_id)

    json(conn, Poison.encode!(consultation_fee))
  end

  # TODO
  def compute_consultation(conn, %{"id" => authorization_id, "params" => params}) do
    authorization = AuthorizationContext.get_authorization_by_id(authorization_id)

    params = %{
      authorization_id: authorization.id,
      member_id: authorization.member.id,
      chief_complaint: "none",
      practitioner_specialization_id: params["practitioner_specialization_id"],
      diagnosis_id: params["diagnosis_id"],
      facility_id: authorization.facility_id,
      consultation_type: "Initial"
    }

    consultation = OPConsultValidator.request_web_ajax(params)

    product_benefit_id = Map.get(consultation.changes, :product_benefit_id) || nil
    product_exclusion_id = Map.get(consultation.changes, :product_exclusion_id) || nil
    benefit_limit = Map.get(consultation.changes, :benefit_limit) || 0
    risk_share_type = Map.get(consultation.changes, :risk_share_type) || ""
    benefit_limit_type = Map.get(consultation.changes, :benefit_limit_type) || nil
    product_limit = Map.get(consultation.changes, :product_limit) || 0
    member_product_id = Map.get(consultation.changes, :member_product_id) || nil
    selected_prod = Map.get(consultation.changes, :selected_product)

    product_code = Map.get(consultation.changes.selected_product, :product_code) || nil

    selected_product =
      with %Innerpeace.Db.Schemas.MemberProduct{} = member_product <-
             Map.get(consultation.changes, :selected_product) do
        %{
          product_name: member_product.account_product.product.name,
          code: member_product.account_product.product.code,
          product_limit: member_product.account_product.product.limit_amount,
          pre_existing_percentage: member_product.pre_existing_percentage,
          vat_status: member_product.vat_status
        }
      else
        _ ->
          %{
            product_name: "",
            code: product_code,
            product_limit: "",
            pre_existing_percentage: 0
          }
      end

    response = %{
      payor_pays: consultation.changes.payor_pays,
      member_pays: consultation.changes.member_pays,
      benefit_limit_type: benefit_limit_type,
      product_name: selected_product.product_name,
      product_code: selected_product.code,
      product_limit: product_limit,
      benefit_limit: benefit_limit,
      risk_share_type: risk_share_type,
      coinsurance: consultation.changes.coinsurance,
      coinsurance_percentage: consultation.changes.coinsurance_percentage,
      copayment: consultation.changes.copayment,
      copayment_percentage: consultation.changes.covered_percentage,
      pre_existing_amount: selected_prod.pre_existing_percentage,
      member_product_id: member_product_id,
      product_benefit_id: product_benefit_id,
      product_exclusion_id: product_exclusion_id,
      vat_status: selected_prod.vat_status,
      consultation_fee: consultation.changes.consultation_fee
    }

    json(conn, Poison.encode!(response))
  end

  # End Consult API

  defp setup_procedure_diagnosis_list(authorization_procedure_diagnoses) do
    for procedure_diagnosis <- authorization_procedure_diagnoses do
      %{
        procedure_id: procedure_diagnosis.payor_procedure_id,
        diagnosis_id: procedure_diagnosis.diagnosis_id,
        unit: procedure_diagnosis.unit
      }
    end
  end

  defp insert_authorization_ruv(authorization_id, facility_ruv_id, current_user) do
    %{
      authorization_id: authorization_id,
      facility_ruv_id: facility_ruv_id,
      created_by_id: current_user.id,
      updated_by_id: current_user.id
    }
    |> AuthorizationContext.create_authorization_ruv()
  end

  def get_amount_by_payor_procedure_id(conn, %{
        "id" => id,
        "facility_id" => facility_id,
        "unit" => unit
      }) do
    amount = AuthorizationContext.get_op_fppr_amount(id, facility_id, unit)
    json(conn, Poison.encode!(amount))
  end

  # ACU API
  def get_facility_room(conn, %{"id" => _authorization_id, "params" => params}) do
    facility_id = params["facility_id"]
    room_id = params["room_id"]

    room_rate = FacilityContext.get_facility_room(facility_id, room_id)
    json(conn, Poison.encode!(room_rate))
  end

  def compute_acu(conn, %{"id" => _authorization_id, "params" => params}) do
    computation = AuthorizationContext.compute_acu(params)
    json(conn, Poison.encode!(computation))
  end

  # End ACU API

  def cancel_loa(conn, %{"id" => _id}) do
    render(conn)
  end

  #  PRINT AUTHORIZATION

  def print_authorization(conn, %{"id" => id, "copy" => copy}) do
    authorization = AuthorizationContext.get_authorization_by_id(id)

    if authorization do
      case authorization.coverage.code do
        "ACU" ->
          print_acu(conn, authorization)

        "OPC" ->
          if copy == "original" do
            print_original_consult(conn, authorization)
          else
            print_duplicate_consult(conn, authorization)
          end

        "EMRGNCY" ->
          print_emergency(conn, authorization)

        "OPL" ->
          print_laboratory(conn, authorization, copy)

        _ ->
          conn
          |> put_flash(:error, "Error printing LOA")
          |> redirect(to: authorization_path(conn, :index))
      end
    else
      conn
      |> put_flash(:error, "Authorization ID was invalid")
      |> redirect(to: authorization_path(conn, :index))
    end
  end

  def print_authorization(conn, %{"id" => id}) do
    authorization = AuthorizationContext.get_authorization_by_id(id)

    if authorization do
      case authorization.coverage.code do
        "ACU" ->
          print_acu(conn, authorization)

        # "OPC" ->
          #   if copy == "original" do
          #     print_original_consult(conn, authorization)
          #   else
          #     print_duplicate_consult(conn, authorization)
          #   end

        "EMRGNCY" ->
          print_emergency(conn, authorization)

        "OPL" ->
          print_laboratory(conn, authorization)

        _ ->
          conn
          |> put_flash(:error, "Error printing LOA")
          |> redirect(to: authorization_path(conn, :index))
      end
    else
      conn
      |> put_flash(:error, "Authorization ID was invalid")
      |> redirect(to: authorization_path(conn, :index))
    end
  end

  def print_original_consult(conn, authorization) do
    member = MemberContext.get_member_any_status(authorization.member_id)

    html =
      View.render_to_string(
        AuthorizationView,
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
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "inline; filename=#{filename}.pdf")
      |> send_resp(200, content)
    else
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to print authorization.")
        |> redirect(to: "/authorizations/#{authorization.id}")
    end
  end

  def print_duplicate_consult(conn, authorization) do
    member = MemberContext.get_member_any_status(authorization.member_id)

    html =
      View.render_to_string(
        AuthorizationView,
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
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "inline; filename=#{filename}.pdf")
      |> send_resp(200, content)
    else
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to print authorization.")
        |> redirect(to: "/authorizations/#{authorization.id}")
    end
  end

  def print_emergency(conn, authorization) do
    html =
      View.render_to_string(
        AuthorizationView,
        "print/emergency_summary.html",
        conn: conn,
        authorization: authorization
      )

    {date, time} = :erlang.localtime()
    unique_id = Enum.join(Tuple.to_list(date)) <> Enum.join(Tuple.to_list(time))
    filename = "#{unique_id}"

    with {:ok, content} <-
           PdfGenerator.generate_binary(html, filename: filename, delete_temporary: true) do
      conn
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "inline; filename=#{filename}.pdf")
      |> send_resp(200, content)
    else
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to print authorization.")
        |> redirect(to: "/authorizations/#{authorization.id}")
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
      View.render_to_string(
        AuthorizationView,
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
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "inline; filename=#{filename}.pdf")
      |> send_resp(200, content)
    else
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to print authorization.")
        |> redirect(to: "/authorizations/#{authorization.id}")
    end
  end

  def print_laboratory(conn, authorization, copy \\ "original") do
    template =
      if copy == "original" do
        "print/laboratory.html"
      else
        "print/laboratory_duplicate.html"
      end
    html =
      View.render_to_string(
        AuthorizationView,
        template,
        conn: conn,
        authorization: authorization
      )

    {date, time} = :erlang.localtime()
    unique_id = Enum.join(Tuple.to_list(date)) <> Enum.join(Tuple.to_list(time))
    filename = "#{unique_id}"

    with {:ok, content} <-
           PdfGenerator.generate_binary(html, filename: filename, delete_temporary: true) do
      conn
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "inline; filename=#{filename}.pdf")
      |> send_resp(200, content)
    else
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to print authorization.")
        |> redirect(to: "/authorizations/#{authorization.id}")
    end
  end

  # END PRINT AUTHORIZATION

  # OTP
  def send_otp(conn, %{"id" => id}) do
    {_, authorization} = AuthorizationContext.insert_otp(id)

    if not is_nil(authorization.member.mobile) do
      # String.replace_leading(authorization.member.mobile, "0", "63")
      # transform number to 639
      member_mobile = UtilityContext.transforms_number(authorization.member.mobile)
      SMS.send(%{text: "Your one-time password is #{authorization.otp}", to: member_mobile})
    end

    render(
      conn,
      Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
      "otp.json",
      otp: authorization.otp,
      otp_expiry: authorization.otp_expiry
    )
  end

  def validate_otp(conn, %{"id" => id, "otp" => otp, "copy" => copy}) do
    authorization = AuthorizationContext.get_authorization_by_id(id)

    case AuthorizationContext.validate_otp(id, otp) do
      {:ok} ->
        if copy == "original" do
        if is_nil(authorization.control_number) do
          authorization
          |> Authorization.changeset_control_number(%{control_number: AuthorizationContext.random_loa_number})
          |> Repo.update()
        end
        render(
          conn,
          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
          "message.json",
          message: "Original Copy"
        )
      else
        render(
          conn,
          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
          "message.json",
          message: "Duplicate Copy"
        )
      end
      {:invalid_otp} ->
        render(
          conn,
          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
          "message.json",
          message: "Invalid OTP"
        )

      {:expired} ->
        render(
          conn,
          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
          "message.json",
          message: "OTP already expired"
        )

      {:otp_not_requested} ->
        render(
          conn,
          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
          "message.json",
          message: "OTP not requested"
        )

      _ ->
        render(
          conn,
          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
          "message.json",
          message: "Invalid PIN"
        )
    end
  end

  def auth_verified(conn, %{"id" => id}) do
    authorization = AuthorizationContext.get_authorization_by_id(id)

    conn
    |> put_flash(:info, "Successfully Availed LOA")
    |> redirect(to: "/authorizations/#{authorization.id}")
  end

  def validate_cvv(conn, %{"id" => id, "cvv" => cvv}) do
    authorization = AuthorizationContext.get_authorization_by_id(id)

    params = %{
      "card_number" => authorization.member.card_no,
      "cvv_number" => cvv
    }

    case AuthorizationContext.validate_card(params, conn.scheme) do
      {true, member} ->
        authorization
        |> Authorization.status_changeset(%{status: "OTP Verified"})
        |> Repo.update()

        render(
          conn,
          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
          "message.json",
          message: "Successful"
        )

      {:invalid_details} ->
        render(
          conn,
          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
          "message.json",
          message: "Invalid CVV"
        )

      {:not_active} ->
        render(
          conn,
          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
          "message.json",
          message: "Member is not Active. Only active members are allowed to request LOA."
        )

      {:api_address_not_exists} ->
        render(
          conn,
          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
          "message.json",
          message: "API address does not exists"
        )

      {:error_connecting_api, response} ->
        render(
          conn,
          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
          "message.json",
          message: "Unable to login to api"
        )

      {:unable_to_login, message} ->
        render(
          conn,
          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
          "message.json",
          message: "Unable to login to api"
        )

      _ ->
        render(
          conn,
          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
          "message.json",
          message: "Invalid CVV"
        )
    end
  end

  def step4_op_consult(conn, authorization) do
    changeset = Authorization.changeset(authorization)
    special_approval = DropdownContext.get_all_special_approval()
    diagnoses = DiagnosisContext.get_all_diagnoses()
    authorization_files = AuthorizationContext.load_authorization_files(authorization.id)

    practitioners =
      PractitionerContext.get_all_practitioners_by_facility_id(authorization.facility_id)

    member = MemberContext.get_a_member!(authorization.member_id)
    specializations = SpecializationContext.get_all_specializations()

    render(
      conn,
      "step4_op_consult.html",
      changeset: changeset,
      special_approval: special_approval,
      diagnoses: diagnoses,
      authorization: authorization,
      practitioners: practitioners,
      specializations: specializations,
      authorization_files: authorization_files,
      member: member
    )
  end

  def filter_practitioner_specialization(conn, %{"val" => val, "facility_id" => facility_id}) do
    result = PractitionerContext.filter_practitioner_specialization(facility_id, val)
    json(conn, Poison.encode!(result))
  end

  def filter_all_practitioner_specialization(conn, %{"facility_id" => facility_id}) do
    result = PractitionerContext.filter_all_practitioner_specialization(facility_id)
    json(conn, Poison.encode!(result))
  end

  def save_draft(conn, %{"id" => authorization_id}) do
    params = %{
      "status" => "Draft",
      "step" => 4
    }

    with {:ok, authorization} <-
      AuthorizationContext.update_authorization(authorization_id, params) do
      insert_log(conn, authorization.id, "saved LOA.")
      conn
      |> put_flash(:info, "Authorization successfully saved!")
      |> redirect(to: "/authorizations")
    else
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to save authorization.")
        |> redirect(to: "/authorizations/#{authorization_id}/setup?step=4")
    end
  end

  def save_authorization_data(conn, authorization_params) do
    user_id = conn.assigns.current_user.id
    authorization = AuthorizationContext.get_authorization_by_id(authorization_params["id"])

    # MEMBER PAYS
    {member_pays, y} =  Float.parse(authorization_params["member_pays"])
    {member_portion, y} =  Float.parse(authorization_params["member_portion"])
    {member_vat_amount, y} =  Float.parse(authorization_params["member_vat_amount"])

    # PAYOR PAYS
    {payor_pays, y} =  Float.parse(authorization_params["payor_pays"])
    {payor_portion, y} =  Float.parse(authorization_params["payor_portion"])
    {payor_vat_amount, y} =  Float.parse(authorization_params["payor_vat_amount"])

    # SPECIAL APPROVAL AMOUNT
    {special_approval_amount, y} =  Float.parse(authorization_params["special_approval_amount2"])
    {sa_portion, y} =  Float.parse(authorization_params["special_approval_portion"])
    {sa_vat_amount, y} =  Float.parse(authorization_params["special_approval_vat_amount"])

    {total_amount, y} =  Float.parse(authorization_params["total_amount"])
    {consultation_fee, y} =  Float.parse(authorization_params["consultation_fee"])
    {pre_existing_amount, y} =  Float.parse(authorization_params["pre_existing_amount"])

    diagnosis_id_trim = String.trim(authorization_params["diagnosis_id"])
    practitioner_specialization_id_trim =
      String.trim(authorization_params["practitioner_specialization_id"])
    product_benefit_id_trim = String.trim(authorization_params["product_benefit_id"])
    member_product_id_trim = String.trim(authorization_params["member_product_id"])
    special_approval_id_trim = String.trim(authorization_params["special_approval_id"])
    product_exclusion_id_trim = String.trim(authorization_params["product_exclusion_id"])

    params = %{
      "internal_remarks" => authorization_params["internal_remarks"],
      "chief_complaint" => String.trim(authorization_params["chief_complaint"]),
      "chief_complaint_others" => String.trim(authorization_params["chief_complaint_others"]),
      "consultation_fee" => Decimal.new(consultation_fee),
      "consultation_type" => String.trim(authorization_params["consultation_type"]),
      "copayment" => Decimal.new(0),
      "coinsurance" => nil,
      "coinsurance_percentage" => nil,
      "pre_existing_percentage" => nil,
      "covered_after_percentage" => nil,
      "pre_existing_amount" => Decimal.new(pre_existing_amount),
      "diagnosis_id" => diagnosis_id_trim,
      "member_covered" => Decimal.new(member_pays),
      "payor_covered" => Decimal.new(payor_pays),
      "member_pay" => Decimal.new(member_pays),
      "member_portion" => Decimal.new(member_portion),
      "member_vat_amount" => Decimal.new(member_vat_amount),
      "payor_pay" => Decimal.new(payor_pays),
      "payor_portion" => Decimal.new(payor_portion),
      "payor_vat_amount" => Decimal.new(payor_vat_amount),
      "special_approval_amount" => Decimal.new(special_approval_amount),
      "special_approval_portion" => Decimal.new(sa_portion),
      "special_approval_vat_amount" => Decimal.new(sa_vat_amount),
      "special_approval_id" => special_approval_id_trim,
      "company_covered" => Decimal.new(0),
      "practitioner_specialization_id" => practitioner_specialization_id_trim,
      "risk_share_type" => nil,
      "member_product_id" => member_product_id_trim,
      "product_benefit_id" => product_benefit_id_trim,
      "product_exclusion_id" => product_exclusion_id_trim,
      "total_amount" => Decimal.new(total_amount)
    }

    with {:ok, authorization2} <-
           AuthorizationContext.save_authorization(authorization, params, user_id) do
      params = Map.put_new(params, "authorization_id", authorization2.id)

      cond do
        diagnosis_id_trim == "" && practitioner_specialization_id_trim == "" ->
          AuthorizationContext.create_authorization_amount(params, user_id)

        diagnosis_id_trim == "" && authorization_params["practitioner_specialization_id"] != "" ->
          AuthorizationContext.create_authorization_practitioner_specialization(params, user_id)
          AuthorizationContext.create_authorization_amount(params, user_id)

        authorization_params["diagnosis_id"] != "" && practitioner_specialization_id_trim == "" ->
          AuthorizationContext.create_authorization_diagnosis(params, user_id)
          AuthorizationContext.create_authorization_amount(params, user_id)

        authorization_params["diagnosis_id"] != "" &&
            authorization_params["practitioner_specialization_id"] != "" ->
          AuthorizationContext.create_authorization_diagnosis(params, user_id)
          AuthorizationContext.create_authorization_practitioner_specialization(params, user_id)
          AuthorizationContext.create_authorization_amount(params, user_id)
      end

      insert_log(conn, authorization.id, "saved LOA.")
      conn
      |> put_flash(:info, "Authorization successfully saved!")
      |> redirect(to: "/authorizations")
    else
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to save authorization.")
        |> redirect(to: "/authorizations/#{authorization.id}/setup?step=4")
    end
  end

  # AUTHORIZATION FILE
  def upload_file(conn, params) do
    authorization_id = params["id"]
    user_id = params["user_id"]
    file = params["file"]
    file_name = params["file_name"]

    case AuthorizationContext.upload_file(
      authorization_id,
      user_id,
      file,
      file_name
    ) do
      {:ok, id} ->
        json conn, %{result: "success", id: id}
      {:error} ->
        json conn, %{result: "error"}
    end
  end

  def delete_file(conn, %{"id" => id}) do
    case AuthorizationContext.delete_file(id) do
      :ok ->
        json conn, %{result: "success"}
      :error ->
        json conn, %{result: "error"}
      {:error, :enoent} #no such file or directtory
        json conn, %{result: "error"}
      _ ->
        json conn, %{result: "error"}
    end
  end
  # AUTHORIZATION FILE

  def delete_authorization(conn, %{"id" => id}) do
    with {:ok, authorization} <- AuthorizationContext.delete_authorization(id) do
      conn
      |> put_flash(:info, "Request successfully deleted")
      |> redirect(to: "/authorizations")
    else
      _ ->
        conn
        |> put_flash(:info, "Error canceling request")
        |> redirect(to: "/authorizations/#{id}/setup?step=4")
    end
  end

  def get_logs(conn, %{"id" => id}) do
    logs = AuthorizationContext.get_authorization_logs(id)
    render(
      conn,
      Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
      "authorization_logs.json",
      logs: logs
    )
  end

  defp insert_log(conn, auth_id, message) do
    current_user = conn.assigns.current_user
    %{
      authorization_id: auth_id,
      user_id: current_user.id,
      message: "#{current_user.username} #{message}"
    } |> AuthorizationContext.insert_log()
  end

  # APPROVE OR DISAPPROVE LOA VALIDATION

  def approve_authorization(conn, %{"id" => id}) do
    authorization_amount = AuthorizationContext.get_auth_amount_by_authorization_id(id)
    user_roles = UserContext.get_user!(conn.assigns.current_user.id).roles
    user_limit =
    if is_nil(user_roles) do
      Decimal.new(0)
    else
      user_limit = List.first(user_roles).approval_limit
      Decimal.new(user_limit || 0)
    end
    if Decimal.to_float(authorization_amount.special_approval_amount) > Decimal.to_float(Decimal.new(0)) do
      render(conn, Innerpeace.PayorLink.Web.AuthorizationView, "message.json", message: "You cannot approve LOAs with special approval.")
    else
      if Decimal.compare(authorization_amount.total_amount, user_limit) == Decimal.new(-1) or
         Decimal.compare(authorization_amount.total_amount, user_limit) == Decimal.new(0)
      do
        with {:ok, authorization} <- AuthorizationContext.approve_authorization(id, conn.assigns.current_user.id) do
          params = %{
            loa_number: authorization.number,
            test: authorization.number
          }
          insert_log(conn, id, "APPROVED LOA.")
          json conn, Poison.encode!(params)
        else
          _ ->
            render(conn, Innerpeace.PayorLink.Web.AuthorizationView, "message.json", message: "Error")
        end
      else
        render(conn, Innerpeace.PayorLink.Web.AuthorizationView, "message.json",
              message: "LOA cannot be approved. The LOA Amount exceeds your approval limit.")
      end
    end
  end

  def disapprove_authorization(conn, %{"id" => authorization_id, "reason" => reason}) do
    with loa = %Authorization{} <- AuthorizationContext.get_authorization_by_id(authorization_id),
         {:ok, loa} <- AuthorizationContext.disapprove_loa(loa, reason)
    do
      insert_log(conn, authorization_id, "DISAPPROVED LOA.")
      json conn, Poison.encode!(true)
    else
      _ ->
      json conn, Poison.encode!(false)
    end
  end

  def edit_authorization_setup(conn, %{"coverage" => coverage, "id" => id}) do
    status = status_checker(conn, id)
    if status.is_edited == false do
      case coverage do
        "OPC" ->
          get_op_consult_details(conn, id)
        true ->
          raise 456
      end
    else
      conn
      |> put_flash(:warning, "LOA cannot be edited. Reason: LOA is currently being processed by #{status.username}")
      |> redirect(to: "/authorizations/#{id}")
    end
  end

  def get_op_consult_details(conn, id) do
    authorization = AuthorizationContext.get_authorization_by_id(id)
    special_approval = DropdownContext.get_all_special_approval()
    diagnoses = DiagnosisContext.get_all_diagnoses()
    authorization_files = AuthorizationContext.load_authorization_files(authorization.id)

    practitioners =
      PractitionerContext.get_all_practitioners_by_facility_id(authorization.facility_id)

    member = MemberContext.get_a_member!(authorization.member_id)
    specializations = SpecializationContext.get_all_specializations()
    date_created = Ecto.DateTime.cast!(authorization.admission_datetime)
    x = {{y, m, d}, time = {h, min, s}} = Ecto.DateTime.to_erl(date_created)
    valid_until =
      ((x |> :calendar.datetime_to_gregorian_seconds) + 86_400)
    valid_until =
      valid_until
      |> :calendar.gregorian_seconds_to_datetime
      |> Ecto.DateTime.cast!
    datetime_now = Ecto.DateTime.from_erl(:erlang.localtime)
    date_result = Ecto.DateTime.compare(datetime_now, valid_until)

    if date_result == :gt do
      conn
      |> put_flash(:error, "LOA cannot be edited")
      |> redirect(to: "/authorizations/#{authorization.id}")
    else
      params = %{
        edited_by_id: conn.assigns.current_user.id,
        updated_by_id: conn.assigns.current_user.id
      }
      with {:ok, authorization} <- AuthorizationContext.update_authorization_edit_status(id, params)
      do
        authorization2 = AuthorizationContext.get_authorization_by_id(id)
        changeset = Authorization.changeset(authorization2)
        render(
          conn,
          "edit/consult/consult_edit.html",
          changeset: changeset,
          special_approval: special_approval,
          diagnoses: diagnoses,
          authorization: authorization2,
          practitioners: practitioners,
          specializations: specializations,
          authorization_files: authorization_files,
          member: member
        )
      else
        _ ->
          conn
          |> put_flash(:error, "Test")
          |> redirect(to: "/authorizations/#{authorization.id}")
      end

    end
  end

  def status_checker(conn, id) do
    edited_by_id = AuthorizationContext.validate_edit_status(id)

    if is_nil(edited_by_id) do
      user = UserContext.get_user!(conn.assigns.current_user.id)
      params = %{
        is_edited: false,
        username: user.username
      }
    else
      user = UserContext.get_user!(edited_by_id)
      if conn.assigns.current_user.id == edited_by_id do
        params = %{
          is_edited: false,
          username: user.username
        }
      else
        params = %{
          is_edited: true,
          username: user.username
        }
      end
    end
  end

  def check_edit_status(conn, %{"id" => id}) do
    edited_by_id = AuthorizationContext.validate_edit_status(id)

    if is_nil(edited_by_id) do
      user = UserContext.get_user!(conn.assigns.current_user.id)
      params = %{
        is_edited: false,
        username: user.username
      }
      json conn, params
    else
      user = UserContext.get_user!(edited_by_id)
      if conn.assigns.current_user.id == edited_by_id do
        params = %{
          is_edited: false,
          username: user.username
        }
        json conn, params
      else
        params = %{
          is_edited: true,
          username: user.username
        }
        json conn, params
      end
    end
  end

  def cancel_edit_opc(conn, %{"id" => id}) do
    params = %{
      edited_by_id: nil
    }

    with {:ok, authorization} <- AuthorizationContext.update_authorization_edit_status(id, params) do
      conn
      |> redirect(to: "/authorizations/#{id}")
    else
      _ ->
        conn
        |> redirect(to: "/authorizations/OPC/#{id}/edit")
    end
  end

  def reschedule_loa(conn, %{"id" => id}) do
    authorization = AuthorizationContext.get_authorization_by_id(id)
    with {:ok, old_authorization} <- AuthorizationContext.update_authorization_reschedule_status(authorization),
         {:ok, new_authorization} <- AuthorizationContext.copy_authorization(authorization) do
          insert_log(conn, old_authorization.id, "rescheduled LOA.")
           params = %{authorization_id: new_authorization.id}
           json conn, params
    else
      _ ->
        conn
    end
  end

  def edit_save(conn, %{
        "id" => authorization_id,
        "step" => step,
        "authorization" => authorization_params
      }) do
    authorization = AuthorizationContext.get_authorization_by_id(authorization_id)

    case step do
      "2" ->
        update_step2(conn, authorization, authorization_params)

      "3" ->
        update_step3(conn, authorization, authorization_params)

      "4" ->
        coverage = CoverageContext.get_coverage(authorization.coverage_id)

        case coverage.name do
          "OP Consult" ->
            log_message = check_authorization_changes(authorization, authorization_params)
            insert_log(conn, authorization_id, "updated #{log_message}.")
            update_step4_op_consult(conn, authorization, authorization_params)

          _ ->
            conn
            |> put_flash(:error, "Invalid coverage!")
            |> redirect(to: authorization_path(conn, :index))
        end
    end
  end

  defp check_authorization_changes(authorization, authorization_params) do
    changeset = Authorization.changeset(authorization, authorization_params)
    message =
      for {key, new_value} <- changeset.changes do
        new_value = transform_string(new_value)
        old_value = Map.get(changeset.data, key)
        old_value = transform_string(old_value)
        "#{transform_atom(key)} from #{old_value} to #{new_value}"
      end
    practitioner_checker = check_consult_practitioner(authorization, authorization_params)
    diagnosis_checker = check_consult_diagnosis(authorization, authorization_params)
    message = message ++ [practitioner_checker] ++ [diagnosis_checker]
    message |> Enum.uniq() |> List.delete("") |> Enum.join(", ")
  end

  defp check_consult_practitioner(authorization, authorization_params) do
    old_practitioner = List.first(authorization.authorization_practitioner_specializations)
    if authorization_params["practitioner_specialization_id"] != old_practitioner.practitioner_specialization_id do
      practitioner_specialization =
        PractitionerContext.get_practitioner_id_by_speciliazation(old_practitioner.practitioner_specialization_id)
      new_practitioner_specialization =
        PractitionerContext.get_practitioner_id_by_speciliazation(authorization_params["practitioner_specialization_id"])
      old_name = "#{practitioner_specialization.practitioner.first_name} #{practitioner_specialization.practitioner.middle_name} #{practitioner_specialization.practitioner.last_name}"
      new_name = "#{new_practitioner_specialization.practitioner.first_name} #{new_practitioner_specialization.practitioner.middle_name} #{new_practitioner_specialization.practitioner.last_name}"
      "Practitioner from #{old_name} to #{new_name}"
    else
      ""
    end
  end

  defp check_consult_diagnosis(authorization, authorization_params) do
    old_diagnosis = List.first(authorization.authorization_diagnosis)
    if authorization_params["diagnosis_id"] != old_diagnosis.diagnosis_id do
      old_diagnosis = DiagnosisContext.get_diagnosis(old_diagnosis.diagnosis_id)
      new_diagnosis = DiagnosisContext.get_diagnosis(authorization_params["diagnosis_id"])
      "Diagnosis from #{old_diagnosis.code} to #{new_diagnosis.code}"
    else
      ""
    end
  end

  defp transform_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&(String.capitalize(&1)))
    |> Enum.join(" ")
  end

  defp transform_string(string) do
    with true <- String.contains?(string, "_") do
      string
      |> String.split("_")
      |> Enum.map(&(String.capitalize(&1)))
      |> Enum.join("  ")
    else
      _ ->
        String.capitalize(string)
    end
  end

  # OP Lab/Emergency
  def create_practitioner_specialization(conn, params) do
    user_id = conn.assigns.current_user.id
    practitioner_specialization =
      PractitionerContext.get_ps_by_id(params["practitioner"]["practitioner_id"], params["practitioner"]["specialization_id"])
    authorization = AuthorizationContext.get_authorization_by_id(params["id"])
    authorization_params = authorization_params(params["practitioner"])
    AuthorizationContext.submit_authorization(authorization, authorization_params, conn.assigns.current_user.id)
     if params["practitioner"]["aps_id"] == "" do
      params =
      %{
        "authorization_id" => authorization.id,
        "practitioner_specialization_id" => practitioner_specialization.id,
        "role" => params["practitioner"]["role"]
      }
      with {:ok, aps} <-
        AuthorizationContext.create_authorization_practitioner_specialization_emergency(params, user_id) do
        conn
        |> put_flash(:info, "Practitioner successfully added!")
        |> redirect(to: "/authorizations/#{aps.authorization_id}/setup?step=4")
      else
        {:already_exist} ->
          conn
          |> put_flash(:error, "Role already added!")
          |> redirect(to: "/authorizations/#{authorization.id}/setup?step=4")
        _ ->
        conn
        |> put_flash(:error, "Error adding practitioner!")
        |> redirect(to: "/authorizations/#{authorization.id}/setup?step=4")
      end
    else
      aps = AuthorizationContext.get_practitioner_specialization_by_aps_id(params["practitioner"]["aps_id"])
      params =
      %{
        "authorization_id" => authorization.id,
        "practitioner_specialization_id" => practitioner_specialization.id,
        "role" => params["practitioner"]["role"]
      }
      with {:ok, aps} <- AuthorizationContext.update_authorization_practitioner_specialization_emergency(aps, params) do
        conn
        |> put_flash(:info, "Practitioner successfully updated!")
        |> redirect(to: "/authorizations/#{aps.authorization_id}/setup?step=4")
      else
        {:already_exist} ->
          conn
          |> put_flash(:error, "Role already added!")
          |> redirect(to: "/authorizations/#{authorization.id}/setup?step=4")
        _ ->
        conn
        |> put_flash(:error, "Error updating practitioner!")
        |> redirect(to: "/authorizations/#{authorization.id}/setup?step=4")
      end
    end
  end

  def delete_practitioner_specialization(conn, %{"id" => id, "aps_id" => aps_id}) do
    aps = AuthorizationContext.get_practitioner_specialization_by_aps_id(aps_id)
    with {:ok, aps} <- AuthorizationContext.delete_authorization_practitioner_specialization(aps) do
      conn
      |> put_flash(:info, "Practitioner successfully deleted!")
      |> redirect(to: "/authorizations/#{id}/setup?step=4")
    else
      _ ->
      conn
      |> put_flash(:error, "Error deleting practitioner!")
      |> redirect(to: "/authorizations/#{id}/setup?step=4")
    end
  end

  def create_disease_procedure(conn, authorization_params) do
    create_authorization_procedure(
      authorization_params["id"],
      authorization_params["authorization"]["diagnosis_id"],
      authorization_params["procedure"],
      conn.assigns.current_user
    )
    authorization = AuthorizationContext.get_authorization_by_id(authorization_params["id"])
    authorization_params = authorization_params(authorization_params["authorization"])
    AuthorizationContext.submit_authorization(authorization, authorization_params, conn.assigns.current_user.id)
    OPLabValidator.validate_authorization(authorization)

    conn
    |> put_flash(:info, "Authorization Procedure/Disease successfully added!")
    |> redirect(to: "/authorizations/#{authorization.id}/setup?step=4")
  end

  def delete_authorization_procedure(conn, %{"id" => id}) do
    authorization_pd = AuthorizationContext.get_authorization_procedure_diagnosis(id)

    with {:ok, authorization_pd} <- AuthorizationContext.delete_authorization_procedure_diagnosis(authorization_pd.id) do
      authorization = AuthorizationContext.get_authorization_by_id(authorization_pd.authorization_id)
      OPLabValidator.validate_authorization(authorization)
      conn
      |> put_flash(:info, "Authorization Procedure/Disease successfully deleted!")
      |> redirect(to: "/authorizations/#{authorization_pd.authorization_id}/setup?step=4")
    else
      _ ->
      conn
      |> put_flash(:error, "Error deleting Authorization Procedure/Disease!")
      |> redirect(to: "/authorizations/#{authorization_pd.authorization_id}/setup?step=4")
    end
  end

  def update_step4_emergency(conn, authorization, authorization_params) do
    if authorization_params["sos"] == "submit" do
      submit_emergency(conn, authorization, authorization_params)
    else
      save_emergency(conn, authorization, authorization_params)
    end
  end

  def submit_emergency(conn, authorization, authorization_params) do
    valid_until =
      ((:erlang.universaltime |> :calendar.datetime_to_gregorian_seconds) + 172_800)
    valid_until =
      valid_until
      |> :calendar.gregorian_seconds_to_datetime
      |> Ecto.DateTime.cast!

    authorization_params =
      authorization_params
      |> Map.put(
        "admission_datetime",
        Ecto.Date.utc()
        |> Ecto.DateTime.from_date()
      )
      |> Map.put(
        "valid_until", valid_until
      )

    user_roles = UserContext.get_user!(conn.assigns.current_user.id).roles

    user_limit =
      if is_nil(user_roles) do
        Decimal.new(0)
      else
        user_limit = List.first(user_roles).approval_limit
        Decimal.new(user_limit || 0)
      end

    with {:ok} <- AuthorizationContext.check_emergency_excess_limits(authorization) do
      if Decimal.compare(authorization.authorization_amounts.total_amount, user_limit) ==
           Decimal.new(1) do
        AuthorizationContext.update_authorization(
          authorization.id,
          %{"status" => "For Approval", "step" => "5"} |> Map.merge(authorization_params)
        )
      else
        AuthorizationContext.update_emergency_approve_authorization(
          authorization.id,
          %{
            "status" => "Approved",
            "step" => 5
          }
          |> Map.merge(authorization_params)
        )
      end
    else
      _ ->
        AuthorizationContext.update_authorization(
          authorization.id,
          %{"status" => "For Approval", "step" => 5} |> Map.merge(authorization_params)
        )
    end

    conn
    |> put_flash(:info, "LOA submitted successfully!")
    |> redirect(to: authorization_path(conn, :index))
  end

  def save_emergency(conn, authorization, authorization_params) do
    user_id = conn.assigns.current_user.id
    authorization = AuthorizationContext.get_authorization_by_id(authorization_params["id"])
    chief_complaint_others =
    if authorization_params["chief_complaint"] == "Others" do
      authorization_params["chief_complaint_others"]
    else
      ""
    end
    params = %{
      "internal_remarks" => authorization_params["internal_remarks"],
      "chief_complaint" => authorization_params["chief_complaint"],
      "chief_complaint_others" => chief_complaint_others,
      "special_approval_id" => authorization_params["special_approval_id"],
      "member_pay" => authorization_params["member_pay"]
    }

    with {:ok, authorization} <- AuthorizationContext.save_authorization(authorization, params, user_id) do
      params = Map.put_new(params, "authorization_id", authorization.id)
      conn
      |> put_flash(:info, "Authorization successfully saved!")
      |> redirect(to: "/authorizations")
    else
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to save authorization.")
        |> redirect(to: "/authorizations/#{authorization.id}/setup?step=4")
    end
  end

  def get_emergency_amount_by_payor_procedure_id(conn, %{
        "id" => id,
        "facility_id" => facility_id,
        "unit" => unit
      }) do
    amount = AuthorizationContext.get_er_fppr_amount(id, facility_id, unit)
    json(conn, Poison.encode!(amount))
  end

  def show_emergency(conn, authorization) do
    changeset = Authorization.changeset(authorization)

    authorization_procedures =
      AuthorizationContext.get_all_authorization_procedure_diagnosis(authorization.id)

    authorization_diagnosis =
      AuthorizationContext.get_all_authorization_procedure_diagnosis(authorization.id)

    special_approval = DropdownContext.get_all_special_approval()
    diagnoses = DiagnosisContext.get_all_diagnosis()

    practitioners =
      PractitionerContext.get_all_practitioners_by_facility_id(authorization.facility_id)

    member = MemberContext.get_a_member!(authorization.member_id)

    procedures =
      ProcedureContext.get_emergency_payor_procedure_by_facility(authorization.facility_id)

    ruvs = RUVContext.get_ruvs()
    facility_contacts = FacilityContext.get_all_facility_contacts(authorization.facility_id)

    render(
      conn,
      "show_emergency.html",
      changeset: changeset,
      procedures: procedures,
      special_approval: special_approval,
      diagnoses: diagnoses,
      authorization_procedures: authorization_procedures,
      authorization_diagnosis: authorization_diagnosis,
      authorization: authorization,
      practitioners: practitioners,
      member: member,
      ruvs: ruvs,
      facility_contacts: facility_contacts
    )
  end

  def get_emergency_solo_amount_by_payor_procedure_id(conn, %{
        "id" => id,
        "facility_id" => facility_id
      }) do
    amount = AuthorizationContext.get_er_fppr_solo_amount(id, facility_id)
    json(conn, Poison.encode!(amount))
  end

  def update_disease_procedure(conn, params) do
    apd = AuthorizationContext.get_authorization_procedure_diagnosis(params["authorization"]["authorization_procedure_id"])
    params =
    %{
      "unit" => params["authorization"]["unit"],
      "amount" => params["authorization"]["amount"]
    }
    with {:ok, apd} <- AuthorizationContext.update_authorization_procedure_diagnosis(apd, params) do
      conn
      |> put_flash(:info, "Successfully updated procedure.")
      |> redirect(to: "/authorizations/#{apd.authorization_id}/setup?step=4")
    else
      _ ->
      conn
      |> put_flash(:error, "Error updating procedure.")
      |> redirect(to: "/authorizations/#{apd.authorization_id}/setup?step=4")

    end
  end

  defp insert_senior(member_id, senior_id) do
    member = MemberContext.get_member(member_id)
    members = MemberContext.get_all_members()
    member_senior_ids = Enum.map(members, fn(x) ->
      senior_id == x.senior_id
    end)
    |> Enum.uniq()
    |> List.delete(false)
    if is_nil(senior_id) do
      {:ok, member}
    else
      if Enum.count(member_senior_ids) > 1 do
        {:already_exist}
      else
        member
        |> Ecto.Changeset.change(%{senior_id: senior_id, senior: true})
        |> Repo.update()
      end
    end
  end

  defp insert_pwd(member_id, pwd_id) do
    member = MemberContext.get_member(member_id)
    members = MemberContext.get_all_members()
    member_pwd_ids = Enum.map(members, fn(x) ->
      pwd_id == x.pwd_id
    end)
    |> Enum.uniq()
    |> List.delete(false)
    if Enum.count(member_pwd_ids) > 1 do
      {:already_exist}
    else
      member
      |> Ecto.Changeset.change(%{pwd_id: pwd_id, pwd: true})
      |> Repo.update()
    end
  end

  def get_facility_room_rate_by_room_number(conn, %{"room_number" => room_number}) do
    facility_room = FacilityRoomRateContext.get_facility_room_rate_by_number(room_number)
    json(conn, Poison.encode!(facility_room))
  end

  def get_authorization_room_and_board_modal(conn, %{"arb_id" => arb_id}) do
    authorization_room = AuthorizationContext.get_authorization_room(arb_id)
    json(conn, Poison.encode!(authorization_room))
  end

  def authorization_index(conn, params) do
    count = AuthorizationDatatable.new_get_clean_auth_count()
    authorizations = AuthorizationDatatable.new_get_clean_auth(params["start"], params["length"], params["search"]["value"])
    conn |> json(%{data: authorizations, draw: params["draw"], recordsTotal: count, recordsFiltered: count})
  end

end
