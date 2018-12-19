defmodule Innerpeace.PayorLink.Web.Api.V1.MemberView do
  use Innerpeace.PayorLink.Web, :view
  alias Innerpeace.Db.Base.AccountContext
  alias Innerpeace.Db.Base.Api.MemberContext
  alias Innerpeace.Db.Base.MemberContext, as: MC

  def render("show_member.json", %{member: member}) do
    render_one(member, Innerpeace.PayorLink.Web.Api.V1.MemberView, "member.json", as: :member)
  end

  def render("show_members.json", %{members: members}) do
    render_many(members, Innerpeace.PayorLink.Web.Api.V1.MemberView, "member.json", as: :member)
  end

  def render("retract.json", %{message: message, code: code}) do
    %{
      "message": message,
      "code": code
    }
  end

  def render("member.json", %{member: member}) do
    %{
      id: member.id,
      card_no: member.card_no,
      account_code: member.account_code,
      account_name: member.account_group.name,
      type: member.type,
      principal_id: member.principal_id,
      first_name_principal: first_name_principal(member.principal_id),
      effectivity_date: member.effectivity_date,
      expiry_date: member.expiry_date,
      first_name: member.first_name,
      middle_name: member.middle_name,
      last_name: member.last_name,
      suffix: member.suffix,
      gender: member.gender,
      civil_status: member.civil_status,
      birthdate: member.birthdate,
      employee_no: member.employee_no,
      date_hired: member.date_hired,
      is_regular: member.is_regular,
      regularization_date: member.regularization_date,
      tin: member.tin,
      philhealth: member.philhealth,
      for_card_issuance: member.for_card_issuance,
      relationship: member.relationship,
      email: member.email,
      email2: member.email2,
      mobile: member.mobile,
      mobile2: member.mobile2,
      telephone: member.telephone,
      fax: member.fax,
      postal: member.postal,
      unit_no: member.unit_no,
      building_name: member.building_name,
      street_name: member.street_name,
      city: member.city,
      province: member.province,
      region: member.region,
      country: member.country,
      status: member.status,
      evoucher_number: member.evoucher_number,
      relationship: member.relationship,
      policy_no: member.policy_no,
      step: member.step,
      attempts: member.attempts,
      attempt_expiry: member.attempt_expiry,
      products: render_many(member.products, Innerpeace.PayorLink.Web.Api.V1.MemberView, "member_product.json", as: :member_product),
      dependents: render_many(member.dependents, Innerpeace.PayorLink.Web.Api.V1.MemberView, "member_dependent.json", as: :member_dependent),
      latest_facility: latest_facility(member),
      number_of_dependents: dependents(member),
      latest_consult: latest_consult(member),
      random_facility1: random_facility1(member),
      random_facility2: random_facility2(member)
    }
  end

  def render("member_product.json", %{member_product: member_product}) do
    %{
      tier: member_product.tier,
      id: member_product.id,
      code: member_product.account_product.product.code,
      name: member_product.account_product.product.name,
      limit_type: member_product.account_product.product.limit_type,
      limit_amoun: member_product.account_product.product.limit_amount,
      hierarchy_waiver: member_product.account_product.product.hierarchy_waiver,
      no_days_valid: member_product.account_product.product.no_days_valid,
      product: render_one(
        member_product.account_product.product,
        Innerpeace.PayorLink.Web.Api.V1.MemberView,
        "product.json",
        as: :product
      )
    }
  end

  def render("product.json", %{product: product}) do
    %{
      name: product.name,
      mded_dependent: product.mded_dependent
    }
  end

  def render("member_dependent.json", %{member_dependent: member_dependent}) do
    %{
      id: member_dependent.id,
      relationship: member_dependent.relationship,
      birthdate: member_dependent.birthdate,
      skipped_dependents: render_many(
        member_dependent.skipped_dependents,
        Innerpeace.PayorLink.Web.Api.V1.MemberView,
        "skipped_dependent.json",
        as: :skipped_dependent
      ),
      gender: member_dependent.gender,
      status: member_dependent.status
    }
  end

  def render("skipped_dependent.json", %{skipped_dependent: skipped_dependent}) do
    if is_nil(skipped_dependent.supporting_document) do
      %{
        first_name: skipped_dependent.first_name,
        last_name: skipped_dependent.last_name,
        relationship: skipped_dependent.relationship,
        suffix: skipped_dependent.suffix,
        gender: skipped_dependent.gender,
        birthdate: skipped_dependent.birthdate,
        reason: skipped_dependent.reason,
        id: skipped_dependent.id
      }
    else
      %{
        first_name: skipped_dependent.first_name,
        last_name: skipped_dependent.last_name,
        relationship: skipped_dependent.relationship,
        suffix: skipped_dependent.suffix,
        gender: skipped_dependent.gender,
        birthdate: skipped_dependent.birthdate,
        reason: skipped_dependent.reason,
        supporting_document: skipped_dependent.supporting_document.file_name,
        id: skipped_dependent.id
      }
    end
  end

  def render("load_all_member.json", %{member: member}) do
    render_many(member, Innerpeace.PayorLink.Web.Api.V1.MemberView, "load_member.json", as: :member)
  end

  def render("load_member.json", %{member: member}) do
    %{
      id: member.id,
      card_no: member.card_no,
      account_code: member.account_code,
      type: member.type,
      principal_id: member.principal_id,
      effectivity_date: member.effectivity_date,
      expiry_date: member.expiry_date,
      first_name: member.first_name,
      middle_name: member.middle_name,
      last_name: member.last_name,
      suffix: member.suffix,
      gender: member.gender,
      civil_status: member.civil_status,
      birthdate: member.birthdate,
      employee_no: member.employee_no,
      date_hired: member.date_hired,
      is_regular: member.is_regular,
      regularization_date: member.regularization_date,
      tin: member.tin,
      philhealth: member.philhealth,
      for_card_issuance: member.for_card_issuance,
      relationship: member.relationship,
      email: member.email,
      email2: member.email2,
      mobile: member.mobile,
      mobile2: member.mobile2,
      telephone: member.telephone,
      fax: member.fax,
      postal: member.postal,
      unit_no: member.unit_no,
      building_name: member.building_name,
      street_name: member.street_name,
      city: member.city,
      province: member.province,
      region: member.region,
      country: member.country,
      status: member.status,
      # card_no: member.card_no,
      # relationship: member.relationship,
      policy_no: member.policy_no
    }
  end

  def render("cancelled_member.json", %{member: member}) do
    %{
      id: member.id,
      card_no: member.card_no,
      cancel_date: member.cancel_date,
      cancel_remarks: member.cancel_remarks,
      cancel_reason: member.cancel_reason,
      effectivity_date: member.effectivity_date,
      expiry_date: member.expiry_date,
      first_name: member.first_name,
      last_name: member.last_name,
      gender: member.gender,
      birthdate: member.birthdate,
    }
  end

  def render("suspended_member.json", %{member: member}) do
    %{
      id: member.id,
      card_no: member.card_no,
      suspend_date: member.suspend_date,
      suspend_remarks: member.suspend_remarks,
      suspend_reason: member.suspend_reason,
      effectivity_date: member.effectivity_date,
      expiry_date: member.expiry_date,
      first_name: member.first_name,
      last_name: member.last_name,
      gender: member.gender,
      birthdate: member.birthdate,
    }
  end

  def render("validate_facility_code.json", %{message: message, code: code}) do
    %{
      message: message,
      code: code
    }
  end

  def render("batch.json", %{members: members}) do
    success = members |> Enum.reject(&(Map.has_key?(&1, :errors)))
    failed = Enum.filter(members, &(Map.has_key?(&1, :errors)))
    %{
      success: render_many(success, Innerpeace.PayorLink.Web.Api.V1.MemberView, "member.json", as: :member),
      failed: render_many(failed, Innerpeace.PayorLink.Web.Api.V1.MemberView, "failed_batch.json", as: :member)
    }
  end

  def render("success.json", %{member: member}) do
    %{
      card_number: member.card_no,
      message: "Successfully added product"
    }
  end

  def render("failed_batch.json", %{member: member}) do
    %{
      params: %{
        account_code: member[:account_code],
        type: member[:type],
        principal_id: member[:principal_id],
        effectivity_date: member[:effectivity_date],
        expiry_date: member[:expiry_date],
        first_name: member[:first_name],
        middle_name: member[:middle_name],
        last_name: member[:last_name],
        suffix: member[:suffix],
        gender: member[:gender],
        civil_status: member[:civil_status],
        birthdate: member[:birthdate],
        employee_no: member[:employee_no],
        date_hired: member[:date_hired],
        is_regular: member[:is_regular],
        regularization_date: member[:regularization_date],
        tin: member[:tin],
        philhealth: member[:philhealth],
        for_card_issuance: member[:for_card_issuance],
        relationship: member[:relationship],
        email: member[:email],
        email2: member[:email2],
        mobile: member[:mobile],
        mobile2: member[:mobile2],
        telephone: member[:telephone],
        fax: member[:fax],
        postal: member[:postal],
        unit_no: member[:unit_no],
        building_name: member[:building_name],
        street_name: member[:street_name],
        city: member[:city],
        province: member[:province],
        region: member[:region],
        relationship: member[:relationship],
        policy_no: member[:policy_no]
      },
      errors: member[:errors]
    }
  end

  def render("utilizations.json", %{utilizations: utilizations}) do
    %{
      utilization: render_many(
        utilizations,
        Innerpeace.PayorLink.Web.Api.V1.MemberView,
        "utilization.json",
        as: :utilization
      )
    }
  end

  def render("utilization.json", %{utilization: utilization}) do
    utilization
  end

  def render("philhealth_status.json", %{status: status}) do
    %{
      status: status,
    }
  end

  def render("product_limits.json", %{member_products: member_products}) do
    render_many(member_products, Innerpeace.PayorLink.Web.Api.V1.MemberView, "product_limit.json", as: :member_product)
  end

  def render("product_limit.json", %{member_product: member_product}) do
    if member_product.type == "ABL" do
      %{
        product_code: member_product.product_code,
        type: member_product.type,
        product_limit: member_product.product_limit,
        utilized_annual_limit: member_product.utilized_annual_limit,
        remaining: Decimal.sub(member_product.product_limit, member_product.utilized_annual_limit),
        # icd: render_many(
        #   member_product.icd,
        #   Innerpeace.PayorLink.Web.Api.V1.MemberView,
        #   "product_icd.json",
        #   as: :icd_group
        # ),
      }
    else
      %{
        product_code: member_product.product_code,
        type: member_product.type,
        product_limit: member_product.product_limit,
        benefits: render_many(
          member_product.benefits,
          Innerpeace.PayorLink.Web.Api.V1.MemberView,
          "product_benefit_abl.json", as: :product_benefit
        )
      }
    end
  end

  def render("product_icd.json", %{icd_group: icd_group}) do
    %{
      icd_group: icd_group.icd_group,
      icd_description: icd_group.icd_description,
      actual_utilized: icd_group.actual_utilized,
      ibnr: icd_group.ibnr
    }
  end

  def render("product_benefit_abl.json", %{product_benefit: product_benefit}) do
    %{
      benefit_code: product_benefit.benefit_code,
      limits: render_many(
        product_benefit.coverages,
        Innerpeace.PayorLink.Web.Api.V1.MemberView,
        "benefit_limit.json",
        as: :benefit_limit
      ),
      icd: render_many(
        product_benefit.icd,
        Innerpeace.PayorLink.Web.Api.V1.MemberView,
        "product_icd.json",
        as: :icd_group
      )
    }
  end

  def render("benefit_limit.json", %{benefit_limit: benefit_limit}) do
    %{
      coverages: benefit_limit.coverage,
      limit_type: benefit_limit.limit_type,
      limit_amoount: benefit_limit.limit_amount,
      limit_classification: benefit_limit.limit_classification,
      utilized_limit: benefit_limit.utilized_limit
    }
  end

  def render("product_benefit_mbl.json", %{product_benefit: product_benefit}) do
    %{
      benefit_code: product_benefit.benefit_code
    }
  end

  def render("member_peme.json", %{peme: peme}) do
    member = peme.member
    male = Enum.map(peme.package.package_payor_procedure, fn(benefit_package) ->
      benefit_package.male
    end)
    female = Enum.map(peme.package.package_payor_procedure, fn(benefit_package) ->
      benefit_package.female
    end)
    age_from = Enum.map(peme.package.package_payor_procedure, fn(benefit_package) ->
      benefit_package.age_from
    end)
    age_to = Enum.map(peme.package.package_payor_procedure, fn(benefit_package) ->
      benefit_package.age_to
    end)

    %{
      id: member.id,
      first_name: member.first_name,
      middle_name: member.middle_name,
      last_name: member.last_name,
      suffix: member.suffix,
      birthdate: member.birthdate,
      civil_status: member.civil_status,
      gender: member.gender,
      male: Enum.member?(male, true),
      female: Enum.member?(female, true),
      age_from: Enum.min(age_from),
      age_to: Enum.max(age_to),
      card_no: member.card_no,
      email: member.email,
      mobile: member.mobile,
      type: member.type,
      account_code: member.account_code,
      account_name:  AccountContext.get_account_by_code(member.account_code).name,
      effectivity_date: member.effectivity_date,
      expiry_date: member.expiry_date,
      card_no: member.card_no
    }
  end

  def render("replicate_member.json", %{member: member}) do
    %{
      id: member.id,
      card_no: member.card_no,
      account_code: member.account_code,
      type: member.type,
      principal_id: member.principal_id,
      effectivity_date: member.effectivity_date,
      expiry_date: member.expiry_date,
      first_name: member.first_name,
      middle_name: member.middle_name,
      last_name: member.last_name,
      suffix: member.suffix,
      gender: member.gender,
      civil_status: member.civil_status,
      birthdate: member.birthdate,
      employee_no: member.employee_no,
      date_hired: member.date_hired,
      is_regular: member.is_regular,
      regularization_date: member.regularization_date,
      tin: member.tin,
      philhealth: member.philhealth,
      for_card_issuance: member.for_card_issuance,
      relationship: member.relationship,
      email: member.email,
      email2: member.email2,
      mobile: member.mobile,
      mobile2: member.mobile2,
      telephone: member.telephone,
      fax: member.fax,
      postal: member.postal,
      unit_no: member.unit_no,
      building_name: member.building_name,
      street_name: member.street_name,
      city: member.city,
      province: member.province,
      region: member.region,
      country: member.country,
      status: member.status,
      policy_no: member.policy_no,
      dependents: render_many(member.dependents, Innerpeace.PayorLink.Web.Api.V1.MemberView, "dependent.json", as: :member_dependent)
    }
  end

  def render("dependent.json", %{member_dependent: member_dependent}) do
    %{
      id: member_dependent.id,
      relationship: member_dependent.relationship,
      birthdate: member_dependent.birthdate,
      gender: member_dependent.gender,
      status: member_dependent.status
    }
  end

  def render("batch2.json", %{members: members}) do
    success = members |> Enum.reject(&(Map.has_key?(&1, :errors)))
    failed = Enum.filter(members, &(Map.has_key?(&1, :errors)))
    %{
      success: render_many(success, Innerpeace.PayorLink.Web.Api.V1.MemberView, "success2.json", as: :member),
      failed: render_many(failed, Innerpeace.PayorLink.Web.Api.V1.MemberView, "failed_batch2.json", as: :member)
    }
  end

  def render("success2.json", %{member: member}) do
    %{
      card_number: member.card_no,
      product_codes: member.product_codes,
      message: "Successfully added product"
    }
  end

  def render("failed_batch2.json", %{member: member}) do
    %{
      card_number: member[:card_number],
      errors: member[:errors]
    }
  end

  def render("batch_remove.json", %{members: members}) do
    success = members |> Enum.reject(&(Map.has_key?(&1, :errors)))
    failed = Enum.filter(members, &(Map.has_key?(&1, :errors)))
    %{
      success: render_many(success, Innerpeace.PayorLink.Web.Api.V1.MemberView, "success_remove.json", as: :member),
      failed: render_many(failed, Innerpeace.PayorLink.Web.Api.V1.MemberView, "failed_batch2.json", as: :member)
    }
  end

  def render("success_remove.json", %{member: member}) do
    %{
      card_number: member.card_no,
      product_codes: member.product_codes,
      message: "Successfully removed product"
    }
  end

  defp first_name_principal(principal_id) do
    if not is_nil(principal_id) do
      MC.get_member!(principal_id).first_name
    else
      ""
    end
  end

  defp latest_facility(member) do
    authorization =
      MC.latest_authorization_facility(member)
    if Enum.empty?(authorization) do
      ""
    else
      Enum.at(authorization, 0).name
    end
  end

  defp dependents(member) do
    if member.type == "Principal" do
      member =
        MC.get_dependents_by_member_id(member.id)
      if Enum.empty?(member) do
        0
      else
        Enum.count(member)
      end
    else
      0
    end
  end

  defp latest_consult(member) do
    member =
      MC.latest_op_consult(member)
    if Enum.empty?(member) do
      "No"
    else
      "Yes"
    end
  end

  def render("security.json", %{member: member}) do
    %{
      id: member.id,
      card_no: member.card_no,
      account_code: member.account_code,
      account_name: AccountContext.get_account_by_code(member.account_code).name,
      type: member.type,
      relationship: member.relationship,
      email: member.email,
      mobile: member.mobile,
      policy_no: member.policy_no,
      latest_facility: latest_facility(member),
      dependents: dependents(member),
      latest_consult: latest_consult(member),
      principal: principal(member),
      random_facility1: random_facility1(member),
      random_facility2: random_facility2(member)
    }
  end

  def random_facility1(member) do
    random_facility =
      MC.random_facility(member, latest_facility(member))
    cond do
      Enum.empty?(random_facility) ->
        ""
      Enum.count(random_facility) < 100 ->
        count = Enum.random(0..Enum.count(random_facility)-1)
        Enum.at(random_facility, count).name
      true ->
        Enum.at(random_facility, Enum.random(0..49)).name
    end
    rescue
    _ ->
      ""
  end

  def random_facility2(member) do
    random_facility =
      MC.random_facility(member, latest_facility(member))
    cond do
      Enum.empty?(random_facility) ->
        ""
      Enum.count(random_facility) < 100 ->
        count = Enum.random(0..Enum.count(random_facility)-1)
        Enum.at(random_facility, count).name
      true ->
        Enum.at(random_facility, Enum.random(50..99)).name
    end
    rescue
    _ ->
      ""
  end


  defp principal(member) do
    if member.type == "Dependent" do
      member =
        MC.get_member(member.principal_id)
        member.first_name
    else
      nil
    end
  end

  def render("return.json", %{return: return}) do
    %{
      results: return
    }
  end

  def render("member_account.json", %{member: member}) do
    %{
      id: member.id,
      card_no: member.card_no,
      account_code: member.account_code,
      type: member.type,
      principal_id: member.principal_id,
      effectivity_date: member.effectivity_date,
      expiry_date: member.expiry_date,
      first_name: member.first_name,
      middle_name: member.middle_name,
      last_name: member.last_name,
      suffix: member.suffix,
      gender: member.gender,
      civil_status: member.civil_status,
      birthdate: member.birthdate,
      employee_no: member.employee_no,
      date_hired: member.date_hired,
      is_regular: member.is_regular,
      regularization_date: member.regularization_date,
      tin: member.tin,
      philhealth: member.philhealth,
      for_card_issuance: member.for_card_issuance,
      relationship: member.relationship,
      email: member.email,
      email2: member.email2,
      mobile: member.mobile,
      mobile2: member.mobile2,
      telephone: member.telephone,
      fax: member.fax,
      postal: member.postal,
      unit_no: member.unit_no,
      building_name: member.building_name,
      street_name: member.street_name,
      city: member.city,
      province: member.province,
      region: member.region,
      country: member.country,
      status: member.status,
      evoucher_number: member.evoucher_number,
      relationship: member.relationship,
      policy_no: member.policy_no,
      step: member.step,
      attempts: member.attempts,
      attempt_expiry: member.attempt_expiry,
      products: render_many(member.products, Innerpeace.PayorLink.Web.Api.V1.MemberView, "member_product_account.json", as: :member_product),
      dependents: render_many(member.dependents, Innerpeace.PayorLink.Web.Api.V1.MemberView, "member_dependent.json", as: :member_dependent),
    }
  end
  def render("member_product_account.json", %{member_product: member_product}) do
    %{
      tier: member_product.tier,
      id: member_product.id,
      code: member_product.account_product.product.code,
      name: member_product.account_product.product.name,
      limit_type: member_product.account_product.product.limit_type,
      limit_amoun: member_product.account_product.product.limit_amount,
      hierarchy_waiver: member_product.account_product.product.hierarchy_waiver,
      no_days_valid: member_product.account_product.product.no_days_valid,
    }
  end

  def render("member_document.json", %{member_document: member_document}) do
    %{
      filename: member_document.filename,
      content_type: member_document.content_type,
      link: member_document.link,
      purpose: member_document.purpose,
      uploaded_from: member_document.uploaded_from,
      date_uploaded: member_document.date_uploaded,
      authorization_id: member_document.authorization_id,
      member_id: member_document.member_id,
      uploaded_by: member_document.uploaded_by,
      status: 200
    }
  end

  def render("links.json", %{url: url, migration_id: migration_id}) do
    %{
      json_link: "#{url}/migration/#{migration_id}/json/result",
      web_page_link: "#{url}/migration/#{migration_id}/results"
    }
  end

  def render("message.json", %{message: message}) do
    %{
      message: message
    }
  end

end
