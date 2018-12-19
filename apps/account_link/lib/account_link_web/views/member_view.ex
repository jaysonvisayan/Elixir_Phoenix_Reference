defmodule AccountLinkWeb.MemberView do
  use AccountLinkWeb, :view

  alias Innerpeace.Db.Base.{
    MemberContext,
    AuthorizationContext,
    AccountContext,
    AcuScheduleContext
  }

  def get_img_url(member) do
    Innerpeace.ImageUploader
    |> AccountLinkWeb.LayoutView.image_url_for(member.photo, member, :original)
    |> String.replace("/apps/account_link/assets/static", "")
  end

  def filter_account_group_products(member) do
    active_account = List.first(member.account_group.account)

    active_account_products =
      if active_account do
        if member.type == "Guardian" do
          Enum.filter(active_account.account_products, &(Enum.member?(&1.product.member_type, "Principal")))
        else
          Enum.filter(active_account.account_products, &(Enum.member?(&1.product.member_type, member.type)))
        end
      end

    account_products =
      if active_account do
        for account_product <- active_account_products, into: [] do
          %{
            description: account_product.product.description,
            code: account_product.product.code,
            name: account_product.product.name,
            id: account_product.id,
            number_of_benefits: Enum.count(account_product.product.product_benefits),
            limit_type: account_product.product.limit_type,
            limit_amount: account_product.product.limit_amount,
            principal_min_age: account_product.product.principal_min_age,
            principal_min_type: account_product.product.principal_min_type,
            principal_max_age: account_product.product.principal_max_age,
            principal_max_type: account_product.product.principal_max_type,
            adult_dependent_min_age: account_product.product.adult_dependent_min_age,
            adult_dependent_min_type: account_product.product.adult_dependent_min_type,
            adult_dependent_max_age: account_product.product.adult_dependent_max_age,
            adult_dependent_max_type: account_product.product.adult_dependent_max_type,
            minor_dependent_min_age: account_product.product.minor_dependent_min_age,
            minor_dependent_min_type: account_product.product.minor_dependent_min_type,
            minor_dependent_max_age: account_product.product.minor_dependent_max_age,
            minor_dependent_max_type: account_product.product.minor_dependent_max_type,
            member_type: account_product.product.member_type
          }
        end
      else
        []
      end

    member_products = for member_product <- member.products, into: [] do
      %{
        description: member_product.account_product.product.description,
        code: member_product.account_product.product.code,
        name: member_product.account_product.product.name,
        id: member_product.account_product.id,
        number_of_benefits: Enum.count(member_product.account_product.product.product_benefits),
        limit_type: member_product.account_product.product.limit_type,
        limit_amount: member_product.account_product.product.limit_amount,
        principal_min_age: member_product.account_product.product.principal_min_age,
        principal_min_type: member_product.account_product.product.principal_min_type,
        principal_max_age: member_product.account_product.product.principal_max_age,
        principal_max_type: member_product.account_product.product.principal_max_type,
        adult_dependent_min_age: member_product.account_product.product.adult_dependent_min_age,
        adult_dependent_min_type: member_product.account_product.product.adult_dependent_min_type,
        adult_dependent_max_age: member_product.account_product.product.adult_dependent_max_age,
        adult_dependent_max_type: member_product.account_product.product.adult_dependent_max_type,
        minor_dependent_min_age: member_product.account_product.product.minor_dependent_min_age,
        minor_dependent_min_type: member_product.account_product.product.minor_dependent_min_type,
        minor_dependent_max_age: member_product.account_product.product.minor_dependent_max_age,
        minor_dependent_max_type: member_product.account_product.product.minor_dependent_max_type,
        member_type: member_product.account_product.product.member_type
      }
    end
    account_products -- member_products
  end

  def render("member.json", %{member: member}) do
    %{
      id: member.id,
      card_no: member.card_no,
      account_code: member.account_code,
      account_name: AccountContext.get_account_by_code(member.account_code).name,
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
      policy_no: member.policy_no,
      step: member.step,
      products: render_many(member.products, AccountLinkWeb.MemberView, "member_product.json", as: :member_product),
      dependents: render_many(member.dependents, AccountLinkWeb.MemberView, "member_dependent.json", as: :member_dependent)
    }
  end

  def render("member_product.json", %{member_product: member_product}) do
    %{
      tier: member_product.tier,
      id: member_product.id,
      code: member_product.account_product.product.code,
      hierarchy_waiver: member_product.account_product.product.hierarchy_waiver,
      name: member_product.account_product.product.name,
      limit_type: member_product.account_product.product.limit_type,
      limit_amoun: member_product.account_product.product.limit_amount
    }
  end

  def render("member_dependent.json", %{member_dependent: member_dependent}) do
    %{
      id: member_dependent.id,
      relationship: member_dependent.relationship,
      birthdate: member_dependent.birthdate,
      skipped_dependents: render_many(member_dependent.skipped_dependents, AccountLinkWeb.MemberView, "skipped_dependent.json", as: :skipped_dependent),
      gender: member_dependent.gender,
      status: member_dependent.status
    }
  end

  def render("skipped_dependent.json", %{skipped_dependent: skipped_dependent}) do
    if is_nil(skipped_dependent.supporting_document) do
    %{
      id: skipped_dependent.id,
      relationship: skipped_dependent.relationship,
      first_name: skipped_dependent.first_name ,
      last_name: skipped_dependent.last_name,
      middle_name: skipped_dependent.middle_name,
      suffix: skipped_dependent.suffix,
      gender: skipped_dependent.gender,
      birthdate: skipped_dependent.birthdate,
      reason: skipped_dependent.reason
    }else
      %{
        first_name: skipped_dependent.first_name ,
        middle_name: skipped_dependent.middle_name,
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

  def filter_account_group_products(member) do
    active_account = List.first(member.account_group.account)
    if active_account do
      active_account_products = Enum.filter(active_account.account_products, &(Enum.member?(&1.product.member_type, member.type)))
      account_products = for account_product <- active_account_products, into: [] do
        %{
          description: account_product.product.description,
          code: account_product.product.code,
          name: account_product.product.name,
          id: account_product.id,
          number_of_benefits: Enum.count(account_product.product.product_benefits),
          limit_type: account_product.product.limit_type,
          limit_amount: account_product.product.limit_amount,
          principal_min_age: account_product.product.principal_min_age,
          principal_max_age: account_product.product.principal_max_age,
          member_type: account_product.product.member_type
        }
      end
    end
  end

  def check_product_age_eligibility(member, product) do
    min_age = get_min_age(member, product)
    min_age_type = get_min_age_type(member, product)
    max_age = get_max_age(member, product)
    max_age_type = get_max_age_type(member, product)

    today = Ecto.Date.to_string(Ecto.Date.utc)
    today = Timex.parse!(today, "%Y-%m-%d", :strftime)
    birthdate = Ecto.Date.to_string(member.birthdate)
    birthdate = Timex.parse!(birthdate, "%Y-%m-%d", :strftime)

    member_min_age = get_member_min_age(member, min_age_type, today, birthdate)
    member_max_age = get_member_max_age(member, max_age_type, today, birthdate)

    if member_min_age >= min_age and member_max_age <= max_age do
      true
    else
      false
    end
  end

  def get_min_age(member, product) do
    case member.relationship do
      "Principal" ->
        product.principal_min_age
      "Spouse" ->
        product.adult_dependent_min_age
      "Parent" ->
        product.adult_dependent_min_age
      "Child" ->
        product.minor_dependent_min_age
      "Sibling" ->
        product.minor_dependent_min_age
      _ ->
        product.principal_min_age
    end
  end

  def get_min_age_type(member, product) do
    case member.relationship do
      "Principal" ->
        product.principal_min_type
      "Spouse" ->
        product.adult_dependent_min_type
      "Parent" ->
        product.adult_dependent_min_type
      "Child" ->
        product.minor_dependent_min_type
      "Sibling" ->
        product.minor_dependent_min_type
      _ ->
        product.principal_min_type
    end
  end

  def get_max_age(member, product) do
    case member.relationship do
      "Principal" ->
        product.principal_max_age
      "Spouse" ->
        product.adult_dependent_max_age
      "Parent" ->
        product.adult_dependent_max_age
      "Child" ->
        product.minor_dependent_max_age
      "Sibling" ->
        product.minor_dependent_max_age
      _ ->
        product.principal_max_age
    end
  end

  def get_max_age_type(member, product) do
    case member.relationship do
      "Principal" ->
        product.principal_max_type
      "Spouse" ->
        product.adult_dependent_max_type
      "Parent" ->
        product.adult_dependent_max_type
      "Child" ->
        product.minor_dependent_max_type
      "Sibling" ->
        product.minor_dependent_max_type
      _ ->
        product.principal_max_type
    end
  end

  def get_member_min_age(member, min_age_type, today, birthdate) do
    case min_age_type do
      "Days" ->
        Timex.diff(today, birthdate, :days)
      "Weeks" ->
        Timex.diff(today, birthdate, :weeks)
      "Months" ->
        Timex.diff(today, birthdate, :months)
      "Years" ->
        age(member.birthdate)
      _ ->
        age(member.birthdate)
    end
  end

  def get_member_max_age(member, max_age_type, today, birthdate) do
    case max_age_type do
      "Days" ->
        Timex.diff(today, birthdate, :days)
      "Weeks" ->
        Timex.diff(today, birthdate, :weeks)
      "Months" ->
        Timex.diff(today, birthdate, :months)
      "Years" ->
        age(member.birthdate)
      _ ->
        age(member.birthdate)
    end
  end

  def age(%Ecto.Date{day: d, month: m, year: y}, as_of \\ :now) do
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

  def member_full_name(member) do
    if is_nil(member.middle_name) == false do
      if is_nil(member.suffix) == false do
        "#{member.first_name} #{member.middle_name} #{member.last_name} #{member.suffix}"
      else
        "#{member.first_name} #{member.middle_name} #{member.last_name}"
      end
    else
      if is_nil(member.suffix) == false do
        "#{member.first_name} #{member.last_name} #{member.suffix}"
      else
        "#{member.first_name} #{member.last_name}"
      end
    end
  end

  def count_result(member_upload_file, status) do
    if status == "success" do
      enroll_count = Enum.count(Enum.filter(member_upload_file.member_upload_logs, & (if &1.status == "success", do: &1)))
      if enroll_count == 0 do
        Enum.count(Enum.filter(member_upload_file.member_maintenance_upload_logs, & (if &1.status == "success", do: &1)))
      else
        enroll_count
      end
    else
      enroll_count = Enum.count(Enum.filter(member_upload_file.member_upload_logs, & (if &1.status == "failed", do: &1)))
      if enroll_count == 0 do
        Enum.count(Enum.filter(member_upload_file.member_maintenance_upload_logs, & (if &1.status == "failed", do: &1)))
      else
        enroll_count
      end
    end
  end

  def get_member_coverages(member) do
    _coverage = AuthorizationContext.get_member_benefit_coverage(member.id)
  end

  def name_checker(middle_name) do
    if is_nil(middle_name) do
      ""
    else
      middle_name
    end
  end

  #member logs
  def render("member_logs.json", %{logs: logs}) do
    for log <- logs do
      %{
        inserted_at: log.inserted_at,
        message: log.message
      }
    end
  end

  def product_used?(used_products, member_product_id) do
    if Enum.member?(used_products, member_product_id) do
      "delete_invalid"
    else
      "delete_product"
    end
  end

  def list_used_products(member_authorizations) do
    used_products =
      Enum.map(member_authorizations, fn(auth) ->
        diagnosis = Enum.map(auth.authorization_diagnosis, &(&1.member_product_id))
        procedure_diagnosis = Enum.map(auth.authorization_procedure_diagnoses, &(&1.member_product_id))
        packages = Enum.map(auth.authorization_benefit_packages, &(&1.member_product_id))
        diagnosis ++ procedure_diagnosis ++ packages
      end)
    used_products |> List.flatten() |> Enum.uniq()
  end

  def display_product_codes(products) do
    product_codes = for member_product <- products, into: [], do: member_product.account_product.product.code
    product_codes = Enum.join(product_codes, ", ")
    if product_codes == "" do
      "n/a"
    else
      product_codes
    end
  end

  def facility_checker(facilities, facility_id) do
    facilities = Poison.decode!(facilities)
    facility = Enum.at(facilities, 0)
    if facility["id"] == facility_id do
      true
    else
      false
    end
  end

  def get_facility(facility_id) do
    facilities = AcuScheduleContext.get_peme_facilities(facility_id)
        |> List.first()

  end

  
end
