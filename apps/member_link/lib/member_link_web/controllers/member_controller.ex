defmodule MemberLinkWeb.MemberController do
  use MemberLinkWeb, :controller

  alias Innerpeace.Db.Base.{
    MemberContext,
    FacilityContext,
    PackageContext,
    UserContext,
    Api.UtilityContext,
    AcuScheduleContext,
    ApiAddressContext,
    AuthorizationContext,
    PemeContext,
    CoverageContext,
    BenefitContext,
    ProductContext,
    UserContext
  }

  alias Innerpeace.Db.Schemas.{
    EmergencyContact,
    Peme,
    Member
  }

  alias Phoenix.Views
  alias MemberLinkWeb.MemberView
  alias MemberLinkWeb.Api.ErrorView
  alias Innerpeace.Db.Validators.PEMEValidator
  alias Innerpeace.Db.Base.Api.AuthorizationContext, as: AuthorizationAPI
  alias MemberLink.Guardian, as: PG
  alias Innerpeace.PayorLink.Web.Api.V1.AuthorizationView
  alias MemberLink.Guardian, as: MG

  def emergency_contact(conn, _params) do
    user = UserContext.get_user!(MG.current_resource(conn).id)
  	render(conn, "emergency_contact.html", user: user)
  end

  def edit_emergency_contact(conn, _params) do
    user = UserContext.get_user!(MG.current_resource(conn).id)
    changeset = MemberContext.emergency_contact_changeset(user)
    render(conn, "edit_emergency_contact_form.html", changeset: changeset, user: user)
  end

  def save_emergency_contact(conn, %{"member" => member_params}) do
    user = UserContext.get_user!(MG.current_resource(conn).id)
    with {:ok, member} <- MemberContext.insert_member_info(user.member, member_params),
         {:ok, _member_emergency_info} <- MemberContext.insert_or_update_member_emergency_info(member, member_params)
    do
      conn
      |> put_flash(:info, "Successfully updated Emergency Contact Info")
      |> redirect(to: member_path(conn, :emergency_contact, conn.assigns.locale))
    else
      _ ->
        conn
        |> put_flash(:info, "Successfully updated Emergency Contact Info")
        |> redirect(to: member_path(conn, :emergency_contact, conn.assigns.locale))
    end
  end

  def evoucher(conn, _params) do
  	render(conn, "verify_evoucher_form.html")
  end

  def verify_evoucher(conn, %{"member" => member_params}) do
    with {:ok, %Peme{} = peme} <- MemberContext.valid_evoucher?(member_params["evoucher_number"], member_params["company_name"]) do
        conn
        |> redirect(to: member_path(conn, :evoucher_member_details, conn.assigns.locale, peme))
    else
      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> render("verify_evoucher_form.html")
    end
  end

  def evoucher_member_details(conn, %{"id" => peme_id}) do
    with {true, _id} <- UtilityContext.valid_uuid?(peme_id),
         %Peme{} = peme <- MemberContext.get_peme(peme_id)
    do
      {m_min_age, m_max_age} = MemberContext.get_package_age(peme, "male")
      {f_min_age, f_max_age} = MemberContext.get_package_age(peme, "female")

      {m_gender} = MemberContext.get_package_gender(peme, "male")
      {f_gender} = MemberContext.get_package_gender(peme, "female")
      # peme = trim_mobile(peme)
      changeset = with true <- not is_nil(peme.member) do
        Member.changeset_peme_evoucher(peme.member)
      else
        _ ->
          Member.changeset_peme_evoucher(%Member{})
      end
      mobiles = [] #MemberContext.get_all_mobile(peme.member.account_code, peme.member_id)
      render(
        conn,
        "evoucher_member_details.html",
        changeset: changeset,
        peme: peme,
        f_min_age: f_min_age,
        f_max_age: f_max_age,
        m_min_age: m_min_age,
        m_max_age: m_max_age,
        m_gender: m_gender,
        f_gender: f_gender,
        mobiles: Poison.encode!(mobiles)
      )
    else
      _ ->
        conn
        |> put_flash(:error, "Invalid")
        |> redirect(to: member_path(conn, :evoucher, conn.assigns.locale))
    end
  end

  defp trim_mobile(peme) do
    if is_nil(peme.member.mobile) do
      peme
    else
      mobile = peme.member.mobile |> String.slice(1..12)
      member = peme.member |> Map.put(:mobile, mobile)
      peme |> Map.put(:member, member)
    end
  end

  def evoucher_member_details_update(conn, %{"id" => peme_id, "member" => member_params}) do
    if is_nil(member_params["primary_id"]) and member_params["primary_photo"] == "" do
      conn
      |> put_flash(:error, "Please Upload Primary ID")
      |> redirect(to: "/#{conn.assigns.locale}/evoucher/#{peme_id}/member_details")
    else
      default_user = UserContext.get_default_user()
      peme = MemberContext.get_peme(peme_id)
      member_params =
        member_params
        |> setup_mobile_params()
        |> setup_birthdate_params()
        |> Map.put("created_by_id", default_user.id)
        |> Map.put("updated_by_id", default_user.id)
        |> Map.put("type", "Principal")
  
      {m_min_age, m_max_age} = MemberContext.get_package_age(peme, "male")
      {f_min_age, f_max_age} = MemberContext.get_package_age(peme, "female")
      result = if member_params["is_edit"] == "true" do
        MemberContext.update_evoucher_member(peme.member, member_params)
      else
        MemberContext.create_evoucher_member(peme, member_params)
      end
      # case MemberContext.update_evoucher_member(peme.member, member_params) do
      case result do
        {:ok, member} ->
          if member_params["primary_photo"] == "" do
            if member_params["primary_id"] do
              MemberContext.update_primary_id(member, member_params)
            end
          else
            primary_photo = MemberContext.convert_base_64_image(%{
              "filename" => "primary_id",
              "extension" => "png",
              "photo" => member_params["primary_photo"]})
              
            MemberContext.update_primary_id(member, %{"primary_id" => primary_photo})
            MemberContext.delete_local_image(%{"filename" => "primary_id", "extension" => "png"})
          end
    
          if member_params["secondary_photo"] == "" do
            if member_params["secondary_id"] do
              MemberContext.update_secondary_id(member, member_params)
            else
              MemberContext.update_secondary_id(member, %{"secondary_id" => nil})
            end
          else
            secondary_photo = MemberContext.convert_base_64_image(%{
              "filename" => "secondary_id",
              "extension" => "png",
              "photo" => member_params["secondary_photo"]})
    
            MemberContext.update_secondary_id(member, %{"secondary_id" => secondary_photo})
            MemberContext.delete_local_image(%{"filename" => "secondary_id", "extension" => "png"})
          end
    
          evoucher_facility_checker(conn, peme)
        {:error, %Ecto.Changeset{} = changeset} ->
          mobiles = []
          render(
            conn,
            "evoucher_member_details.html",
            changeset: changeset,
            peme: peme,
            f_min_age: f_min_age,
            f_max_age: f_max_age,
            m_min_age: m_min_age,
            m_max_age: m_max_age,
            mobiles: Poison.encode!(mobiles)
          )
      end
    end
  end

  defp evoucher_facility_checker(conn, peme) do
    if is_nil(peme.facility_id) do
      conn
      |> redirect(to: member_path(conn, :evoucher_select_facility, conn.assigns.locale, peme))
    else
      conn
      |> redirect(to: member_path(conn, :evoucher_select_facility, conn.assigns.locale, peme))
      # MemberContext.update_peme_status(peme, %{status: "Registered"})
      # conn
      # |> redirect(to: member_path(conn, :evoucher_summary, conn.assigns.locale, peme))
    end
  end

  def evoucher_select_facility(conn, %{"id" => peme_id}) do
    peme = MemberContext.get_peme(peme_id)
    changeset = Peme.changeset_facility(peme)
    member = peme.member |> MemberContext.preload_member_products()
    product_codes = Enum.map(member.products, &(&1.account_product.product.code))
    # facilities = AcuScheduleContext.get_peme_facilities(product_codes, peme.package_id)
    if not is_nil(peme.facility_id) do
      facilities = peme_facility_checker(peme.facility_id)
    else
      facilities = peme_facility_checker(product_codes, peme.package_id)
    end
    render(
      conn,
      "evoucher_select_facility.html",
      peme: peme,
      changeset: changeset,
      facilities: Poison.encode!(facilities)
    )
  end

  defp get_user(nil), do: UserContext.check_user_by_username("masteradmin")
  defp get_user(id) do
      UserContext.get_user(id)
    rescue
       _ ->
      UserContext.check_user_by_username("masteradmin")
  end

  def evoucher_select_facility_update(conn, %{"id" => peme_id, "peme" => peme_params}) do
    # member_params =
    #   member_params
    #   |> setup_mobile_params()
    #   |> setup_birthdate_params()
    peme = MemberContext.get_peme(peme_id)
    with {:ok, peme} <- MemberContext.update_peme_facility(peme, peme_params["facility_id"])
    do
      # MemberContext.update_peme_status(peme, %{status: "Registered"})
      # conn
      # |> redirect(to: member_path(conn, :evoucher_summary, conn.assigns.locale, peme))
      #         member = result.member
      facility = FacilityContext.get_facility(peme.facility_id)
      peme_facility = facility.code
      member = peme.member
      rp_params = %{
        "origin" => "Memberlink",
        "member_id" => peme.member_id,
        "facility_code" => peme_facility,
        "card_no" => peme.member.card_no,
        "coverage_code" => "PEME",
        "evoucher" => peme.evoucher_number,
        "admission_datetime" => peme.date_from,
        "discharge_datetime" => peme.date_to
      }

      # evoucher_facility_checker(conn, peme)
      registered_date = Ecto.DateTime.from_erl(:calendar.now_to_datetime(:erlang.now))
      user = get_user(peme.created_by_id)
      with {:ok, peme} <- MemberContext.update_peme_status(peme, %{status: "Registered", registration_date: registered_date}),
              {:ok, pm_param} <- PemeContext.request_peme(conn, rp_params, user)#,
              #{:ok, changeset} <- PEMEValidator.request_peme(pm_param)#,
              # {:ok, response} <- AuthorizationAPI.request_peme_loa_providerlink(conn, pm_param, rp_params["evoucher"])
          do

            conn
            |> put_flash(:info, "Pre-employment Medical Examination Application form Submitted")
            |> redirect(to: member_path(conn, :evoucher_summary, conn.assigns.locale, peme))

          else
            # {:error, changeset} ->
            #   conn
            #   |> put_flash(:error, changeset)
            #   |> redirect(to: member_path(conn, :evoucher_select_facility, conn.assigns.locale, peme))
            {:error, error} ->
              conn
              |> put_flash(:error, "LOA: #{error}")
              |> redirect(to: member_path(conn, :evoucher_select_facility, conn.assigns.locale, peme))

            {:error_login_api, error} ->
                conn
                |> put_flash(:error, "#{error}")
                |> redirect(to: member_path(conn, :evoucher_select_facility, conn.assigns.locale, peme))

            {:error, "invalid_params"} ->
              conn
              |> put_flash(:error, "LOA: Invalid Parameters")
              |> redirect(to: member_path(conn, :evoucher_select_facility, conn.assigns.locale, peme))

            {:error, "Error creating loa in providerlink."} ->
              conn
              |> put_flash(:error, "Error Creating Loa in Providerlink.")
              |> redirect(to: member_path(conn, :evoucher_select_facility, conn.assigns.locale, peme))

            _ ->
              conn
              |> put_flash(:error, "Error creating loa")
              |> redirect(to: member_path(conn, :evoucher_select_facility, conn.assigns.locale, peme))
          end
      else
      {:error, changeset} ->
        conn
        |> redirect(to: member_path(conn, :evoucher_select_facility, conn.assigns.locale, peme))
    end
  end

  defp peme_facility_checker(facility_id) do
    AcuScheduleContext.get_peme_facilities(facility_id)
  end

  defp peme_facility_checker(product_codes, package_id) do
    AcuScheduleContext.get_peme_facilities(product_codes, package_id)
  end

  # defp request_peme_loa_2(conn, rp_params) do
  #   with {:ok, pm_param} <- get_peme_details(conn, rp_params) do
  #     {:ok, pm_param}
  #   else
  #     {:error, changeset} ->
  #       {:error, changeset}
  #     {:error, error} ->
  #       {:error, error}
  #     {:error, "invalid_params"} ->
  #      {:error, "invalid_params"}
  #     _ ->
  #       {:error}
  #   end
  # end

  defp request_peme_loa_2(conn, rp_params) do
    with {:ok, token} <- UtilityContext.payorlink_v2_sign_in() do
      api_address = ApiAddressContext.get_api_address_by_name("PAYORLINK_2")
      payorlink_url = "#{api_address.address}/api/v1/loa/details/peme/get_all_details"
      headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
      body = Poison.encode!(rp_params)
      with {:ok, response} <- HTTPoison.post(payorlink_url, body, headers, []) do
        if response.status_code == 200 do
          {:ok, response}
        else
          resp = Poison.decode!(response.body)
          message = resp["message"]
          {:error_login_api, message}
        end
      else
        {:unable_to_login, "Error occurs when attempting to login in Payorlink"} ->
          {:unable_to_login_payorlink_api}
        _ ->
          {:unable_to_sign_in_payorlink}
      end
    else
      _ ->
        {:unable_to_sign_in_payorlink, "Error: Sign-in Payorlink"}
    end
  end

    defp request_peme_loa_providerlink(conn, params, evoucher) do
     with {:ok, token} <- AcuScheduleContext.providerlink_sign_in_v2() do
       api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
       providerlink_url = "#{api_address.address}/api/v1/peme/insert_loa"
       headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
       param =
           params
           |> Map.put(:evoucher, evoucher)

       body = create_json_params(param)
       with {:ok, response} <- HTTPoison.post(providerlink_url, body, headers) do
         resp = Poison.decode!(response.body)
         if resp["message"] == "Succesfully Created Peme Loa" do
           {:ok, response}
         else
           AuthorizationContext.delete_authorization_peme_accountlink(params.authorization_id)
           {:error, "Error creating loa in providerlink."}
         end
       else
         _ ->
           AuthorizationContext.delete_authorization_peme_accountlink(params.authorization_id)
           {:error}
       end

     else
        _ ->
            AuthorizationContext.delete_authorization_peme_accountlink(params.authorization_id)
            {:unable_to_login, "Unable to login to ProviderLink API"}
      end
    end

    defp create_json_params(params) do
     {_, package_name} = Enum.at(params.package, 2)
     loa_number = AuthorizationContext.get_loa_number_by_loa_id(params.authorization_id)
      account_name = MemberContext.get_member_account_name_by_code(params.member.account_code)
     male = if params.member.gender == "Male", do: true, else: false
     female = if params.member.gender == "Female", do: true, else: false
     params = %{
       "admission_date" => params.admission_date,
       "discharge_date" => params.discharge_date,
       "facility_id" => params.facility_id,
       "first_name" => params.member.first_name,
       "middle_name" => params.member.middle_name,
       "last_name" => params.member.last_name,
       "suffix" => params.member.suffix,
       "birthdate" => params.member.birthdate,
       "card_no" => params.member.card_no,
       "id" => params.member.id,
       "male" => male,
       "female" => female,
       "member_status" => "Active",
       "email" => params.member.email,
       "mobile" => params.member.mobile,
       "evoucher_number" => params.evoucher,
       "type" => params.member.type,
       "account_code" => params.member.account_code,
       "package_facility_rate" => params.package_facility_rate,
       "authorization_id" => params.authorization_id,
       "number" => loa_number,
       "evoucher" => params.evoucher,
       "account_name" => account_name,
       "gender" => params.member.gender,
       # loa_packages
       "benefit_package_id" => params.benefit_package_id,
       "package_name" => package_name,
       "benefit_code" => params.benefit_code,
       "payor_procedure" => params.payor_procedure,
       "package_facility_rate" => params.package_facility_rate
     }|> Poison.encode!()
    end

    def get_peme_details(conn, params) do
      # current_peme = MemberContext.get_peme_by_evoucher(params["evoucher"])
      # default_user = current_peme.created_by

      default_user = UserContext.get_default_user()

      result = if is_nil(Guardian.Plug.current_resource(conn)) do
        %{user: default_user, accountlink_web: false}
      else
        %{user: default_user, accountlink_web: true}
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
        facility = FacilityContext.get_facility!(facility_code)
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
        payor_procedures = payor_procedures(package, member)

        with true <- AuthorizationAPI.validate_peme_member(member, coverage, facility.id),
             true <- AuthorizationAPI.validate_peme(member, coverage),
             true <- AuthorizationAPI.validate_peme_existing(member, coverage, facility.id),
             true <- AuthorizationAPI.validate_peme_pf(facility.id, member.id, coverage)
        do
          package_facility_rate =
            package_facility_rate(
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
            "updated_by_id" => user.id,
            "origin" => origin,
            "is_peme" => true,
            "status" => ap_status
          }

          with {:ok, authorization} <-
            AuthorizationContext.create_authorization_api(
              user.id,
              authorization_params
            )
          do
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
              peme: peme,
              internal_remarks: authorization.internal_remarks,
              product_id: product.id,
               facility_id: facility.id,
               coverage_id: coverage.id,
               user_id: user.id,
               member: member
             }
             {:ok, pm_param}

          else
            {:error, changeset} ->
              {:error, changeset}
          end

          else
          {:invalid_coverage, error} ->
            {:error, error}
        end

        else
         {:error, "invalid_params"}
      end
    end

    defp package_facility_rate(package_facilities, facility_id) do
      if Enum.count(package_facilities) > 1 do
        rate = for package_facility <- package_facilities do
          if package_facility.facility_id == facility_id do
            package_facility.rate
          end
        end

        rate =
          rate
          |> Enum.uniq()
          |> List.delete(nil)
          |> List.first()
      else
        package_facility = List.first(package_facilities)
        rate = package_facility.rate
      end
    end

    def payor_procedures(package, member) do
      birthdate_array =
        member.birthdate
        |> Ecto.Date.to_string()
        |> String.split("-")
        |> Enum.map(&(String.to_integer(&1)))

      {:ok, birthdate} =
        Date.new(
          Enum.at(birthdate_array, 0),
          Enum.at(birthdate_array, 1),
          Enum.at(birthdate_array, 2)
        )

      age = age(birthdate)

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
    end

    defp error_msg(conn, status, message) do
      conn
      |> put_status(status)
      |> render(MemberLinkWeb.Api.ErrorView, "error.json", message: message, code: status)
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

  defp setup_mobile_params(params) do
    with true <- Map.has_key?(params, "mobile") do
      number =
        params["mobile"]
        |> String.slice(1, 12)
        |> String.replace("-", "")
      params
      |> Map.put("mcc", "+63")
      |> Map.put("mobile", number)
    else
      _ ->
        params
    end
  end

  defp setup_birthdate_params(params) do
    with true <- Map.has_key?(params, "birthdate") do
      {mm, dd, year} =
        params["birthdate"]
        |> String.split("-")
        |> List.to_tuple()
      params
      |> Map.put("birthdate", "#{year}-#{mm}-#{dd}")
    else
      _ ->
        params
    end
  end

  def evoucher_reprint(conn, _params) do
  	render(conn, "evoucher_reprint_form.html")
  end

  def evoucher_reprint_validate(conn, %{"member" => member_params}) do
    member_params = setup_mobile_params(member_params)
    with %Peme{} = peme <- MemberContext.valid_evoucher_reprint?(member_params["mobile"], member_params["company_name"]) do
        conn
        |> redirect(to: member_path(conn, :evoucher_summary, conn.assigns.locale, peme))
    else
      _ ->
        conn
        |> put_flash(:error, "Mobile number and/or company is invalid")
  	    |> render("evoucher_reprint_form.html")
    end
  end

  def evoucher_summary(conn, %{"id" => peme_id}) do
    peme = MemberContext.get_peme(peme_id)
  	render(conn, "evoucher_summary.html", peme: peme)
  end

  def evoucher_print_preview(conn, %{"id" => peme_id}) do
    peme = MemberContext.get_peme(peme_id)
    if not is_nil(peme) do
      html = Phoenix.View.render_to_string(
        MemberView,
        "evoucher_preview.html",
        peme: peme
      )
      filename = "#{Ecto.Date.utc()}"
      {:ok, content} = PdfGenerator.generate_binary(html, filename: filename, delete_temporary: true)
      conn
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "inline; filename=#{filename}.pdf")
      |> send_resp(200, content)
    else
      json conn, %{result: "Peme member has not been found."}
    end
  end

  def evoucher_render(conn, %{"id" => peme_id}) do
    peme = MemberContext.get_peme(peme_id)
    procedures = MemberContext.get_peme_procedures(peme_id)
    html = Phoenix.View.render_to_string(
      MemberView,
      "evoucher_print_loa.html",
      peme: peme,
      procedures: procedures
    )
    json(conn, %{html: html})
  end

  def evoucher_summary_print(conn, %{"id" => peme_id, "peme" => peme_params}) do
    procedures = MemberContext.get_peme_procedures(peme_id)
    peme = MemberContext.get_peme(peme_id)
    if not is_nil(peme) do
      html = Phoenix.View.render_to_string(
        MemberView,
        "evoucher_print_loa.html",
        peme: peme,
        procedures: procedures,
        locale: conn.assigns.locale,
        canvas: peme_params["base64"]
      )
      filename = "#{Ecto.Date.utc()}"
      {:ok, content} = PdfGenerator.generate_binary(html, filename: filename, delete_temporary: true)
      conn
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "attachment; filename=#{filename}.pdf")
      |> send_resp(200, content)
    else
      json conn, %{result: "Peme member has not been found."}
    end
  end

  def remove_primary_id(conn, %{"id" => id}) do
    peme = MemberContext.get_peme(id)
    member = MemberContext.get_a_member!(peme.member_id)
    changeset = Member.changeset_update_evoucher(member)
    # mobiles = MemberContext.get_all_mobile(peme.account_group.code, member.id)

    with {:ok, member} <- MemberContext.update_primary_id(member, %{"primary_id" => nil})
    do
      conn
      |> put_flash(:info, "Primary ID Successfully Removed.")
      |> redirect(
        to: member_path(conn, :evoucher_member_details_update, conn.assigns.locale, id),
        changeset: changeset, id: id, member: member
      )
    else
      _->
        conn
        |> put_flash(:error, "Error in Removing Primary ID.")
        |> redirect(
          to: member_path(conn, :evoucher_member_details_update, conn.assigns.locale, id),
          changeset: changeset, id: id, member: member
        )
    end
  end

  def remove_secondary_id(conn, %{"id" => id}) do
    peme = MemberContext.get_peme(id)
    member = MemberContext.get_a_member!(peme.member_id)
    changeset = Member.changeset_update_evoucher(member)
    # mobiles = MemberContext.get_all_mobile(peme.account_group.code, member.id)

    with {:ok, member} <- MemberContext.update_secondary_id(member, %{"secondary_id" => nil})
    do
      conn
      |> put_flash(:info, "Secondary ID Successfully Removed.")
      |> redirect(
        to: member_path(conn, :evoucher_member_details_update, conn.assigns.locale, id),
        changeset: changeset, id: id, member: member
      )
    else
      _->
        conn
        |> put_flash(:error, "Error in Removing Secondary ID.")
        |> redirect(
          to: member_path(conn, :evoucher_member_details_update, conn.assigns.locale, id),
          changeset: changeset, id: id, member: member
        )
    end
  end

end
