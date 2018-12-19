defmodule Innerpeace.PayorLink.Web.Api.V1.AuthorizationView do
  use Innerpeace.PayorLink.Web, :view
  alias Innerpeace.PayorLink.Web.LayoutView
  alias Innerpeace.Db.Base.Api.UtilityContext
  alias Ecto.Date

  def render("eligible.json", %{multiple: multiple}) do
    %{
      message: "Eligible",
      multiple: multiple
    }
  end

  def render("eligible.json", _) do
    %{
      message: "Eligible"
    }
  end

  def render("list_loa.json", %{loa: loa}) do
    %{
      loa: render_many(loa, Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "loa.json", as: :loa)
    }
  end

  def render("loa.json", %{loa: loa}) do
    %{
      id: loa.id,
      number: loa.number,
      request_datetime: loa.inserted_at,
      admission_datetime: loa.admission_datetime,
      coverage: loa.coverage.name,
      validated: true,
      status: loa.status,
      chief_complaint: loa.chief_complaint,
      origin: loa.origin,
      transaction_id: loa.transaction_no,
      control_number: loa.control_number,
      amount: render_one(loa.authorization_amounts,
        Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "amount.json", as: :amount),
      facility: render_one(loa.facility,
        Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "provider.json", as: :provider),
      practitioner: render_many(loa.authorization_practitioners,
        Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "doctor.json", as: :doctor),
      diagnosis: render_many(loa.authorization_diagnosis,
        Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "authorization_diagnosis.json", as: :authorization_diagnosis)
    }
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
      company_pays: amount.company_covered
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
      id: doctor.practitioner_id,
      name:
        Enum.join([doctor.practitioner.first_name, doctor.practitioner.middle_name, doctor.practitioner.last_name], "  "),
      prc_no: doctor.practitioner.prc_no,
      specialization: render_one(doctor.practitioner.practitioner_specializations,
        Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "practitioner_specializations.json", as: :practitioner_specializations),
      sub_specialization:
        Enum.filter(render_many(doctor.practitioner.practitioner_specializations,
          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
            "practitioner_sub_specializations.json", as: :practitioner_sub_specializations), & !is_nil(&1))
    }
  end

  def render("practitioner_specializations.json", %{practitioner_specializations: practitioner_specializations}) do
    specializations = for pf <- practitioner_specializations do
      if pf.type  == "Primary" do
        pf.specialization
      end
    end
    specializations = Enum.filter(specializations, & !is_nil(&1))
    if specializations == [] do
    %{
    }
    else
    %{
      name: Enum.at(specializations, 0).name
    }
    end
  end
  def render("practitioner_sub_specializations.json", %{practitioner_sub_specializations: practitioner_specializations}) do
      if practitioner_specializations.type  == "Secondary" do
    %{
      name: practitioner_specializations.specialization.name
    }
      end
  end

  def render("otp.json", %{otp: otp, otp_expiry: otp_expiry}) do
    %{
      otp: otp,
      otp_expiry: otp_expiry
    }
  end

  def render("message.json", %{message: message}) do
    %{
      message: message
    }
  end

  def render("acu_details.json", %{member: member, authorization: authorization,
    benefit_packages: benefit_packages, facility: facility})
  do
    if Enum.count(benefit_packages) > 1 do
    %{
      authorization_id: authorization.id,
      request_date: authorization.inserted_at,
      loa_number: authorization.number,
      benefit_packages: Enum.map(benefit_packages, fn(bp) ->
        package_facility_rate =
          package_facility_rate(
            bp.benefit_package.package.package_facility,
            facility.id
          )

        pbl = List.first(bp.product_benefit.product_benefit_limits)
        limit_amount = if is_nil(pbl) do
          Decimal.new(0)
        else
          pbl.limit_amount || Decimal.new(0)
        end

        %{
          acu_type: bp.benefit_package.benefit.acu_type,
          acu_coverage: bp.benefit_package.benefit.acu_coverage,
          benefit_package_id: bp.benefit_package.id,
          benefit_code: bp.benefit_package.benefit.code,
          benefit_provider_access: bp.benefit_package.benefit.provider_access,
          limit_amount: limit_amount,
          package: render_one(
            bp.benefit_package.package,
            Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
            "package.json",
            as: :package),
          package_facility_rate: package_facility_rate,
          payor_procedure: render_many(
            payor_procedures(bp.benefit_package.package, member),
            Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
            "payor_procedure.json",
            as: :payor_procedure
          )
        }
      end)
    }
    else
    bp = List.first(benefit_packages)
    package_facility_rate =
      package_facility_rate(
        bp.benefit_package.package.package_facility,
        facility.id
      )

    pbl = List.first(bp.product_benefit.product_benefit_limits)
    limit_amount = if is_nil(pbl) do
      Decimal.new(0)
    else
      pbl.limit_amount || Decimal.new(0)
    end

    %{
      authorization_id: authorization.id,
      request_date: authorization.inserted_at,
      loa_number: authorization.number,
      acu_type: bp.benefit_package.benefit.acu_type,
      acu_coverage: bp.benefit_package.benefit.acu_coverage,
      benefit_package_id: bp.benefit_package.id,
      benefit_code: bp.benefit_package.benefit.code,
      benefit_provider_access: bp.benefit_package.benefit.provider_access,
      limit_amount: limit_amount,
      package: render_one(
        bp.benefit_package.package,
        Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
        "package.json",
        as: :package),
      package_facility_rate: package_facility_rate,
      payor_procedure: render_many(
        payor_procedures(bp.benefit_package.package, member),
        Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
        "payor_procedure.json",
        as: :payor_procedure
      )
    }
    end
  end

  def render("acu_details2.json", %{filtered_available_mp: filtered_available_mp, authorization: authorization}) do
    %{
      member_usable_products: render_many(filtered_available_mp, Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "usable_detail.json", as: :usable_detail)
    }
  end
  def render("usable_detail.json", %{usable_detail: usable_detail}), do: usable_detail

  def render("package.json", %{package: package}) do
    %{
      id: package.id,
      code: package.code,
      name: package.name
    }
  end

  def render("payor_procedure.json", %{payor_procedure: payor_procedure}) do
    %{
      id: payor_procedure.procedure.id,
      code: payor_procedure.procedure.code,
      description: payor_procedure.procedure.description
    }
  end

  def payor_procedures(package, member) do
    age = age(member.birthdate)

    payor_procedure = for ppp <- package.package_payor_procedure do
      if (ppp.male and member.gender == "Male") or
      (ppp.female and member.gender == "Female") do
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

  def package_facility_rate(package_facilities, facility_id) do
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

  def render("acu_loa.json", %{loa: loa}) do
    %{
      id: loa.id,
      number: loa.number,
      coverage: loa.coverage.name,
      status: loa.status,
      created_by_id: loa.created_by_id,
      request_datetime: loa.inserted_at,
      admission_datetime: loa.admission_datetime,
      discharge_datetime: loa.discharge_datetime,
      approved_datetime: loa.approved_datetime,
      approved_by_id: loa.approved_by_id,
      origin: loa.origin,
      amount: render_one(
        loa.authorization_amounts,
        Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
        "amount.json", as: :amount
      ),
      facility: render_one(
        loa.facility,
        Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
        "provider.json", as: :provider
      ),
      diagnosis: render_many(
        loa.authorization_diagnosis,
        Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
        "authorization_diagnosis.json", as: :authorization_diagnosis
      )
    }
  end

  def render("authorization_logs.json", %{logs: logs}) do
    render_many(logs, Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "authorization_log.json", as: :log)
  end

  def render("authorization_log.json", %{log: log}) do
    %{
      message: UtilityContext.sanitize_value(log.message),
      user: UtilityContext.sanitize_value(log.user.username),
      inserted_at: UtilityContext.sanitize_value(log.inserted_at)
    }
  end

  def render("reschedule_loa.json", %{loa: loa}) do
    %{
      old_authorization_id: loa.old_authorization_id,
      new_authorization_id: loa.id,
      member: loa.member_id,
      member_name: loa.member.first_name,
      date: loa.admission_datetime,
      status: loa.status
    }
  end

  def render("authorization_pos_terminal.json", %{loa: loa}) do
    %{
      transaction_id: loa.transaction_no,
      loe_no: loa.loe_number,
      member: render_one(loa.member, Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "member.json", as: :member),
      account: render_one(loa.member.account_group,
                          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "account.json", as: :account),
      facility: render_one(loa.facility, Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "facility.json", as: :facility),
      coverage: loa.coverage.name,
      datetime_swipe: loa.swipe_datetime,
      generated_from: loa.origin,

    }
  end

  def render("member.json", %{member: member}) do
    %{
      name: member_full_name(member),
      card_no: member.card_no,
      effective_date: member.effectivity_date,
      expiry_date: member.expiry_date,
      birth_date: member.birthdate,
      age: age(member.birthdate),
      gender: member.gender,
      status: member.status
    }
  end

  defp member_full_name(member) do
    if is_nil(member.suffix) do
      if is_nil(member.middle_name) do
        "#{member.last_name}, #{member.first_name}"
      else
        "#{member.last_name}, #{member.first_name} #{member.middle_name}"
      end
    else
      if is_nil(member.middle_name) do
        "#{member.last_name} #{member.suffix}, #{member.first_name}"
      else
        "#{member.last_name} #{member.suffix}, #{member.first_name} #{member.middle_name}"
      end
    end
  end

  def render("account.json", %{account: account}) do
    %{
      code: account.code,
      name: account.name,
      effective_date: List.first(account.account).start_date,
      expiry_date: List.first(account.account).end_date,
      status: List.first(account.account).status
    }
  end

  def render("facility.json", %{facility: facility}) do
    %{
      code: facility.code,
      name: facility.name,
      type: facility.type,
      category: facility.category,
      address: p_display_complete_address(facility),
      contact: facility.phone_no
    }
  end

  def render("vendor_op_consult_print.json", %{authorization: authorization, conn: conn}) do
    url =
    if Application.get_env(:payor_link, :env) == :prod do
      Atom.to_string(conn.scheme) <> "://" <> Innerpeace.PayorLink.Web.Endpoint.struct_url.host
    else
      Innerpeace.PayorLink.Web.Endpoint.url
    end

    %{
      loa_number: authorization.number,
      pdf_link: "#{url}/authorizations/#{authorization.id}/#{authorization.print_type}/print_authorization",
      status: authorization.status,
      remarks: authorization.internal_remarks || ""
    }
  end

  def render("vendor_op_consult.json", %{authorization: authorization}) do
    %{
      loa_number: authorization.number,
      pdf_link: "",
      status: authorization.status,
      remarks: authorization.internal_remarks || ""
    }
  end

  def render("vendor_acu.json", %{authorization: authorization, conn: conn}) do
    url =
    if Application.get_env(:payor_link, :env) == :prod do
      Atom.to_string(conn.scheme) <> "://" <> Innerpeace.PayorLink.Web.Endpoint.struct_url.host
    else
      Innerpeace.PayorLink.Web.Endpoint.url
    end

    %{
      loa_number: authorization.number,
      pdf_link: "#{url}/authorizations/#{authorization.id}/print_authorization",
      status: authorization.status,
      remarks: authorization.internal_remarks || ""
    }
  end

  def render("vendor_acu_executive.json", %{benefit: benefit}) do
    %{
      acu_type: benefit.acu_type,
      acu_coverage: benefit.acu_coverage,
      message: "Discharge Date is required",
      reason: "ACU Type is Executive and ACU Coverage is Inpatient"
    }
  end

  def p_display_complete_address(facility) do
    "#{facility.line_1}, #{facility.line_2}, #{facility.city},
    #{facility.province}, #{facility.region}, #{facility.country}"
  end

  #PEME DETAILS

  def render("peme_details.json", %{member: member, benefit: benefit,
  benefit_package: benefit_package, package: package,
  payor_procedures: payor_procedures, authorization: authorization})
  do
    %{
      authorization_id: authorization.id,
      benefit_package_id: benefit_package.id,
      benefit_code: benefit.code,
      package: render_one(
        package,
        Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
        "package.json",
        as: :package),
      package_facility_rate: package.package_facility_rate,
      payor_procedure: render_many(
        payor_procedures,
        Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
        "payor_procedure.json",
        as: :payor_procedure
      )
    }
  end

  # def render("payorlink_one_peme_member.json", %{member: member}) do
  #  gender = if member.gender == "Male", do: "m", else: "f"
  #   name = UtilityContext.get_username_by_user_id(member.created_by_id)
  #   %{
  #     "CorpCode": member.account_code,
  #     "UpdatedBy": name,
  #     "CreatedBy": name,
  #     "EndorsedBy": name,
  #     "FirstName": member.first_name,
  #     "LastName": member.last_name,
  #     "LinkID": "LinkID",
  #     "IntlCoverage":"PEME",
  #     "BirthDate": member.birthdate,
  #     "MI": UtilityContext.get_middle_initial_member(member.middle_name),
  #     "Gender": gender,
  #     "CivilStat": member.civil_status,
  #     "OrigEffectiveDate": member.effectivity_date,
  #     "EffectiveDate": member.effectivity_date,
  #     "ExpiryDate": member.expiry_date,
  #     # "Dental" => "",
  #     # "Maternity" => "",
  #     # "Life" => "",
  #     # "SOS" => "",
  #     # "OPMeds" => "",
  #     "MemberType": "P",
  #     "Relationship": "Principal"
  #     # "Extension" => ""
  #   }
  # end

  def render("approve_loa.json", %{authorization: authorization}) do
   %{
      loa_number: authorization.number,
      status: authorization.status
    }
  end

  def render("claims.json", %{claims: claims}) do
    batch_nos =
      claims
      |> Enum.map(&(&1.batch_no))
      |> UtilityContext.unique_list()

    batches = for batch_no <- batch_nos do
      claims_data =
        claims
        |> Enum.map(fn(x) -> if x.batch_no == batch_no, do: x end)
        |> UtilityContext.unique_list()

      claim = List.first(claims_data)

      batch_file = get_by_key_value(get_bf(claim), :batch_files)

      pathsample = ""

      asodoc = get_asodoc(File.read(pathsample), batch_file)

      estimated_bill  =
        claims_data
        |> Enum.map(&(&1.authorization.authorization_amounts.total_amount))
        |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

      %{
        batch_no: batch_no,
        payor_code: "MAXICAR",
        provider_code: claim.facility.code,
        estimatedclaims: Enum.count(claims_data),
        estimatedbills: estimated_bill,
        remarks: "",
        created_by: claim.created_by.username,
        ref_no: claim.transaction_no,
        coverage: claim.coverage.name,
        received_date: get_by_key_value(get_bf(claim), :date_received),
        due_date: get_by_key_value(get_bf(claim), :date_due),
        physician_code: "",
        provider_instruction: "",
        "ASODOC": "",
        "AttachedDoc": asodoc,
        loes: render_many(
          claims_data,
          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
          "loes.json",
          as: :loes),
      }
    end

    if Enum.empty?(batches) do
      render_one("claims not found", Innerpeace.PayorLink.Web.Api.V1.AuthorizationView, "message.json", as: :message)
    else
      List.first(batches)
    end
  end

  defp get_pathsample(nil, _), do: ""
  defp get_pathsample(bff, env) when env in [:test, :dev] do
    pathsample = Path.expand('./')
    path =
      Innerpeace.FileUploader
      |> LayoutView.file_url_for(bff.type, bff)
      |> String.replace("/apps/payor_link/assets/static", "")
      |> String.slice(0..-15)

    "#{pathsample}#{path}"
  end
  defp get_pathsample(bff, :prod) do
    path =
      Innerpeace.FileUploader
      |> LayoutView.file_url_for(bff.type, bff)
      |> String.replace("/apps/payor_link/assets/static", "")
      |> String.slice(0..-15)
    
    File.mkdir_p!(Path.expand('./uploads/files'))
    pathsample = Path.expand('./uploads/files/')
    Download.from(path, [path: "#{pathsample}/#{bff.name}"])

    "#{pathsample}/#{bff.name}"
  end
  defp get_pathsample(_, _), do: nil

  defp get_asodoc({:ok, file}, bf) do
    pathsample = Path.expand('./uploads/files/')
    File.rm_rf("#{pathsample}/#{bf.file.name}")
    listname = String.split(bf.file.name, ".")
    i = Enum.count(listname)
    ext = Enum.at(listname, i-1)

    "#{ext}-#{Base.encode64(file)}"
  end
  defp get_asodoc(_, _), do: ""

  def render("claims2.json", %{claims: claims}) do
    %{
      batch_no: claims.batch_no,
      soa_ref_no: claims.soa_ref_no,
      soa_amount: claims.soa_amount,
      computed_soa_amount: claims.edited_soa_amount,
      payor_code: "MAXICAR",
      provider_code: claims.provider_code,
      estimatedclaims: claims.estimatedclaims,
      estimatedbills: claims.estimatedbills,
      remarks: "",
      created_by: claims.created_by,
      ref_no: claims.soa_ref_no,
      coverage: claims.coverage,
      received_date: claims.received_date,
      due_date: claims.due_date,
      physician_code: "",
      provider_instruction: "",
      "ASODOC": "",
      "AttachedDoc": claims[:AttachedDoc],
      loes: render_many(
        claims.loes,
        Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
        "loes.json",
        as: :loes),
    }
  end

  def render("claims3.json", %{claims: claim}) do
    %{
      # loa_id: claim.authorization_id,
      number: claim.number,
      is_claimed?: claim.is_claimed?,
      approved_datetime: claim.approved_datetime,
      step: claim.step,
      valid_until: claim.valid_until,
      migrated: claim.migrated,
      origin: claim.origin,
      admission_datetime: claim.admission_datetime,
      # discharge_datetime: Ecto.DateTime.cast!(claim.discharge_datetime),
      status: claim.status,
      version: claim.version,
      transaction_no: claim.transaction_no,
      batch_no: claim.batch_no,
      payorlink_claim_id: claim.id,
      inserted_at: Ecto.DateTime.utc(),
      updated_at: Ecto.DateTime.utc(),
      package: claim.package,
      diagnosis: claim.diagnosis,
      procedure: claim.procedure
    }
  end

  def render("loes.json", %{loes: loe}) do
    package_code =
      if not is_nil(loe.package_code) do
        loe.package_code
        |> List.first()
      else
        ""
      end
    package_name =
      if not is_nil(loe.package_name) do
        loe.package_name
        |> List.first()
      else
        ""
      end

      %{
        card_no: loe.member.card_no,
        patient_name:  Enum.join([loe.member.first_name, loe.member.middle_name, loe.member.last_name], "  "),
        availment_date: loe.admission_datetime,
        discharge_date: loe.admission_datetime,
        loa_id: loe.authorization.number,
        assessed_amount: loe.authorization.authorization_amounts.total_amount,
        created_by: loe.created_by.username,
        requested_by: loe.created_by.username,
        remarks: "",
        email: loe.member.email,
        mobile: loe.member.mobile,
        ref_type: "",
        ip_address: "",
        "package_code": package_code,
        "package_name": package_name,
        "ICDCode": render_one(
          loe.authorization,
          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
          "icd.json" ,
          as: :auth),
        "CPTList": render_one(
          loe.authorization,
          Innerpeace.PayorLink.Web.Api.V1.AuthorizationView,
          "cpt.json" ,
          as: :auth),
      }
  end

  def render("icd.json", %{auth: auth}) do
    for icd <- auth.authorization_diagnosis do
    %{
      "ICDCode": icd.diagnosis.code,
      "ICDDesc": icd.diagnosis.description,
      "EstimatePrice": auth.authorization_amounts.total_amount
    }
    end
  end

  def render("cpt.json", %{auth: auth}) do
    abp = List.first(auth.authorization_benefit_packages)
    ad = List.first(auth.authorization_diagnosis)
    bp = abp.benefit_package
    p = bp.package
    ppps = p.package_payor_procedure
    for ppp <- ppps do
      %{
        "BenefitID": bp.package.code,
        "CptCode": ppp.payor_procedure.procedure.code,
        "CptDesc": ppp.payor_procedure.procedure.description,
        "EstimatePrice": "",
        "IcdCode": ad.diagnosis.code,
        "LimitCode": ""
      }
    end
  end

  defp get_bf(nil), do: nil
  defp get_bf(claim), do: get_bf_v2(claim.authorization)
  defp get_bf_v2(nil), do: nil
  defp get_bf_v2(auth), do: get_bf_v3(auth.batch_authorizations)
  defp get_bf_v3([]), do: nil
  defp get_bf_v3([batch_auths | _]), do: get_bf_v4(batch_auths)
  defp get_bf_v4(nil), do: nil
  defp get_bf_v4(batch_auth), do: get_bf_v5(batch_auth.batch)
  defp get_bf_v5(nil), do: nil
  defp get_bf_v5(batch), do: batch

  def get_by_key_value(nil, _), do: ""
  def get_by_key_value(data, key) do
    {_, value} = Map.fetch(data, key)
    value
  end

end
