defmodule Innerpeace.PayorLink.Web.Main.MemberView do
  use Innerpeace.PayorLink.Web, :view
  alias Innerpeace.Db.Base.MemberContext
  alias Innerpeace.Db.Base.AuthorizationContext
  alias Innerpeace.Db.Base.BatchContext
  alias Innerpeace.Db.Base.DropdownContext
  alias Innerpeace.PayorLink.Web.LayoutView


  def map_accounts(accounts) do
    accounts
    |> Enum.map(&{&1.account_group.code, &1.account_group.code})
    |> Enum.sort()
  end

  def map_accounts2(accounts) do
    accounts
    |> Enum.map(&{"#{&1.account_group.code} - #{&1.account_group.name}", &1.account_group.code})
    |> Enum.sort()
  end

  def map_principal_members(members) do
    members
    |> Enum.map(&{"#{&1.id} - #{&1.first_name} #{&1.middle_name} #{&1.last_name}", &1.id})
    |> Enum.sort()
  end

  def map_principal_members(members, member_id) do
    members
    |> Enum.reject(&(&1.id == member_id))
    |> Enum.map(&{"#{&1.id} - #{&1.first_name} #{&1.middle_name} #{&1.last_name}", &1.id})
  end

  def map_product_codes(products) do
    products
    |> Enum.map(&(&1.code))
    |> Enum.sort()
  end

  def check_active_step(conn, step) do
    step = Integer.to_string(step)
    current_step = conn.params["step"]
    if step == current_step do
      "active"
    else
      if String.to_integer(step) < String.to_integer(current_step) do
        "completed"
      else
        "disabled"
      end
    end
  end

  def display_full_name(member) do
    "#{member.first_name} #{member.middle_name} #{member.last_name}"
  end

  def display_product_codes(products) do
    product_codes = for member_product <- products, into: [], do: member_product.account_product.product.code
    product_codes = Enum.join(product_codes, ", ")
    if product_codes == "" do
      "none"
    else
      product_codes
    end
  end

  # def get_created_by(user) do

  # end

  def get_img_url(member) do
    Innerpeace.ImageUploader
    |> LayoutView.image_url_for(member.photo, member, :original)
    |> String.replace("/apps/payor_link/assets/static", "")
  end

  def get_account_group_start_date(account_group) do
    active_account = List.first(account_group.account)
    if active_account do
      active_account.start_date
    else
      "n/a"
    end
  end

  def get_account_group_end_date(account_group) do
    active_account = List.first(account_group.account)
    if active_account do
      active_account.end_date
    else
      "n/a"
    end
  end

  def get_member_account_code(account_group) do
    active_account = List.first(account_group.account)
    active_account.code
  end

  def get_member_account_funding_arrangement(account_group) do
    active_account = List.first(account_group.account)
    active_account.funding_arrangement
  end

  def get_member_account_status(account_group) do
    active_account = List.first(account_group.account)
    #if active_account do
    active_account.status
    #else
    #"Inactive"
    #end
  end

  def get_member_account(account_group) do
    List.first(account_group.account)
  end

  # def display_member_product_coverages(member_product) do
  #raise member_product.product.product_benefits
  # end

  defp check_benefits(benefits) do
    for b <- benefits do
      coverages = Enum.map(b.benefit_coverages, &(&1.coverage.code))
      if Enum.member?(coverages, "ACU") do
        b
      else
        nil
      end
    end
    |> Enum.uniq
    |> List.delete(nil)
  end

  def check_age(package_payor_procedures, member) do
    age_from =
      for ppp <- package_payor_procedures do
        ppp.age_from
      end

    age_from =
      if not Enum.empty?(age_from) do
        age_from
        |> Enum.min()
      else
        age_from = nil
      end

    age_to =
      for ppp <- package_payor_procedures do
        ppp.age_to
      end

    age_to =
      if not Enum.empty?(age_to) do
        age_to
        |> Enum.max()
      else
        age_to = nil
      end

    cond do
      is_nil(age_from) or is_nil(age_to) ->
        true
      age_from <= age(member.birthdate) >= age_to ->
        true
      true ->
        {:invalid_age}
    end
  end

  defp check_gender(package_payor_procedures, member) do
    male =
      for ppp <- package_payor_procedures do
        ppp.male
      end

    female =
      for ppp <- package_payor_procedures do
        ppp.female
      end

    if String.downcase("#{member.gender}") == "male" do
      cond do
        Enum.empty?(male) ->
          true
        Enum.member?(male, true) ->
          true
        true ->
          {:invalid_gender}
      end
      else
        cond do
          Enum.empty?(female) ->
            true
          Enum.member?(female, true) ->
            true
          true ->
            {:invalid_gender}
        end
    end
  end

  def filter_account_group_products(member) do
    active_account =
      member.account_group.account
      |> Enum.filter(&(&1.status == "Active"))
      |> Enum.at(0)

    if active_account do
      if member.type == "Guardian" do
        active_account_products = Enum.filter(
          active_account.account_products,
          &(Enum.member?(&1.product.member_type, "Principal"))
        )
      else
        active_account_products = Enum.filter(
          active_account.account_products,
          &(Enum.member?(&1.product.member_type, member.type))
        )
      end
    end

    if active_account do
      account_products = for account_product <- active_account_products, into: [] do
        packages =
          account_product.product.product_benefits
          |> Enum.map(&(&1.benefit))
          |> check_benefits()
          |> Enum.map(&(&1.benefit_packages))
          |> List.flatten()
          |> Enum.map(&(&1.package))
          age =
            packages
            |> Enum.map(&(&1.package_payor_procedure))
            |> List.flatten()
            |> check_age(member)

            gender =
              packages
              |> Enum.map(&(&1.package_payor_procedure))
              |> List.flatten()
              |> check_gender(member)

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
                member_type: account_product.product.member_type,
                product_id: account_product.product.id,
                mded_principal: account_product.product.mded_principal,
                mded_dependent: account_product.product.mded_dependent,
                gender: gender,
                age: age
              }
      end
      else
      account_products = []
    end
    member_products = for member_product <- member.products, into: [] do
      packages =
        member_product.account_product.product.product_benefits
        |> Enum.map(&(&1.benefit))
        |> check_benefits()
        |> Enum.map(&(&1.benefit_packages))
        |> List.flatten()
        |> Enum.map(&(&1.package))

      age =
        packages
        |> Enum.map(&(&1.package_payor_procedure))
        |> List.flatten()
        |> check_age(member)

      gender =
        packages
        |> Enum.map(&(&1.package_payor_procedure))
        |> List.flatten()
        |> check_gender(member)

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
        member_type: member_product.account_product.product.member_type,
        product_id: member_product.account_product.product.id,
        mded_principal: member_product.account_product.product.mded_principal,
        mded_dependent: member_product.account_product.product.mded_dependent,
        gender: gender,
        age: age
      }
    end
    account_products -- member_products
  end

  def active_tab_checker(tab) do
    case tab do
      "profile" ->
        {"active", "", "", "", ""}
      "product" ->
        {"", "active", "", "", ""}
      "card_transactions" ->
        {"", "", "active", "", ""}
      "dependent_info" ->
        {"", "", "", "active", ""}
      "utilization" ->
        {"", "", "", "", "active"}
      nil ->
        {"active", "", "", "", ""}
      _ ->
        {"active", "", "", "", ""}
    end
  end

  def check_product_age_eligibility(member, product) do
    with nil <- check_if_birthdate_available(member.birthdate) do
      nil
    else
      _ ->
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

        with true <- member_min_age >= min_age,
             true <- member_max_age <= max_age,
             true <- product.gender,
             true <- product.age
        do
          true
        end
    end
  end

  defp check_if_birthdate_available(member_birthdate), do: member_birthdate
  defp check_if_birthdate_available(nil), do: nil

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
  rescue
    _ ->
      "N/A"
  end
  def age(_, _), do: "N/A"

  def do_age(birthday, :now) do
    {today, _time} = :calendar.now_to_datetime(:erlang.now)
    calc_diff(birthday, today)
  end

  def do_age(birthday, date), do: calc_diff(birthday, date)

  def calc_diff({y1, m1, d1}, {y2, m2, d2}) when m2 > m1 or (m2 == m1 and d2 >= d1) do
   y2 - y1
  end

  def calc_diff({y1, _, _}, {y2, _, _}), do: (y2 - y1) - 1

  def count_result(member_upload_file) do
    result = Enum.into(member_upload_file.member_upload_logs, [], &(&1.status))

    %{
      "success" => Enum.count(result, &(&1 == "success")),
      "failed" => Enum.count(result, &(&1 == "failed")),
      "total" => Enum.count(result)
    }
  end

  def cop_count_result(member_upload_file) do
    result = Enum.into(member_upload_file.member_cop_upload_logs, [], &(&1.status))

    %{
      "success" => Enum.count(result, &(&1 == "success")),
      "failed" => Enum.count(result, &(&1 == "failed")),
      "total" => Enum.count(result)
    }
  end

  def render("skipping.json", %{skipped_dependents: skipped_dependents}) do
    for skipped_dependent <- skipped_dependents do
      if is_nil(skipped_dependent.supporting_document) do
        %{
          first_name: skipped_dependent.first_name ,
          last_name: skipped_dependent.last_name,
          relationship: skipped_dependent.relationship,
          suffix: skipped_dependent.suffix,
          gender: skipped_dependent.gender,
          birthdate: skipped_dependent.birthdate,
          reason: skipped_dependent.reason
        }
      else
        %{
          first_name: skipped_dependent.first_name ,
          last_name: skipped_dependent.last_name,
          relationship: skipped_dependent.relationship,
          suffix: skipped_dependent.suffix,
          gender: skipped_dependent.gender,
          birthdate: skipped_dependent.birthdate,
          reason: skipped_dependent.reason,
          supporting_document: skipped_dependent.supporting_document.file_name
        }
      end
    end
  end

  def get_all_skipping(member) do
    %{
      member_name: member.first_name <> " " <> member.last_name,
      account_name_code: member.account_code <> " " <> member.account_group.name,
      member_id: member.id,
      skipped_dependent: get_skipping(member),
      date_request: DateTime.to_date(Enum.at(member.skipped_dependents, 0).inserted_at),
      requested_by: Enum.at(member.skipped_dependents, 0).created_by.username,
      requested_from: "Payorlink"
    }
  end

  def get_skipping(member) do
    for skipped_dependent <- member.skipped_dependents do
      [
        skipped_dependent.first_name <> " " <> skipped_dependent.last_name,
        skipped_dependent.relationship,
        Ecto.Date.to_string(skipped_dependent.birthdate),
        skipped_dependent.gender,
        skipped_dependent.reason,
        Innerpeace.FileUploader
        |> LayoutView.file_url_for(skipped_dependent.supporting_document, skipped_dependent)
        |> String.replace("/apps/payor_link/assets/static", "")
      ] |> Enum.join(",")
    end
    |> Enum.join(",")
  end

  def get_payor_pays(member_product_id, effectivity_date, expiry_date) do
    AuthorizationContext.get_used_limit_per_product_in_op_consult(member_product_id, effectivity_date, expiry_date)
  end

  def map_products(products) do
    Enum.into(products, [], &({&1.account_product.product.name, &1.account_product.product.id}))
  end

  def empty_value(_), do: "N/A"
  def empty_value(value), do: value

  def authorization_practitioner([], coverage), do: "N/A"
  def authorization_practitioner(authorization, coverage) do
    if coverage == "op consult" do
        aps = authorization.authorization_practitioner_specializations
        aps
        |> Enum.into([], &(Enum.join([&1.practitioner_specialization.practitioner.first_name, &1.practitioner_specialization.practitioner.last_name], " ")))
        |> Enum.join(", ")
    else
      "N/A"
    end
  end

  defp results_one(auth) do
    auth.authorization_diagnosis
     |> Enum.into([], fn(ad) ->
         if is_nil(ad.product_benefit) do
           []
         else
           ad.product_benefit.benefit.name
         end
       end)
     |> Enum.uniq()
     |> Enum.join(", ")
     |> result_value()
  end

  defp results_two(auth) do
    auth.authorization_procedure_diagnoses
     |> Enum.into([], fn(apd) ->
         if is_nil(apd.product_benefit) do
           []
         else
           apd.product_benefit.benefit.name
         end
       end)
     |> Enum.uniq()
     |> Enum.join(", ")
     |> result_value()
  end

  defp results_three(auth) do
    auth.authorization_benefit_packages
     |> Enum.into([], fn(abp) ->
         if is_nil(abp.benefit_package) do
           []
        else
           abp.benefit_package.benefit.name
         end
       end)
     |> Enum.uniq()
     |> Enum.join(", ")
     |> result_value()
  end

  def benefits_list(auth, coverage) do
    cond do
      coverage  == "op consult" ->
        results_one(auth)
      coverage == "op laboratory" || coverage == "emergency" || coverage == "inpatient" ->
        results_two(auth)
      coverage  == "acu" ->
        results_three(auth)
      true ->
      "N/A"
    end
  end

  defp result_value(result) do
    if result == "" do
      "N/A"
    else
      result
    end
  end

  def display_special_approval(authorization) do
    if is_nil(authorization.special_approval_id) do
      "N/A"
    else
      DropdownContext.get_dropdown(authorization.special_approval_id).value
    end
  end

  # def render("upload_status.json", %{member_upload_file: member_upload_file}) do
  #   %{
  #     batch_no: member_upload_file.batch_no,
  #     count: member_upload_file.count,
  #     filename: member_upload_file.filename,
  #     upload_type: member_upload_file.upload_type
  #   }
  # end

  #member logs
  def render("member_logs.json", %{logs: logs}) do
    for log <- logs do
      %{
        inserted_at: log.inserted_at,
        message: log.message
      }
    end
  end

  def render("load_search_members.json", %{members: members}) do
    %{member: render_many(members, Innerpeace.PayorLink.Web.MemberView, "member.json", as: :member)}
  end

  def render("member.json", %{member: member}) do
    %{
      id: member.id,
      name: Enum.join([member.first_name, member.last_name], " "),
      card_no: member.card_no,
      account: member.account_group.name,
      status: member.status,
      step: member.step
    }
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

  def display_principal_id(member) do
    if member.type == "Dependent" do
      "#{member.principal_id} - #{member.principal.first_name} #{member.principal.last_name}"
    else
      nil
    end
  end

  def display_principal_product(member) do
    cond do
      member.type == "Dependent" and is_nil(member.prinicipal_member_product) ->
        "Invalid Principal Member Product"
      member.type == "Dependent" and not is_nil(member.prinicipal_member_product) ->
        "#{member.prinicipal_member_product.account_product.product.code} - #{member.prinicipal_member_product.account_product.product.hierarchy_waiver}"
      true ->
        nil
    end
  end

  def display_relationship(member) do
    if member.type == "Dependent" do
      member.relationship
    else
      nil
    end
  end

  def list_account_employee_nos(account_group, member_emp_no) do
    emp_nos = Enum.map(account_group.members, &(&1.employee_no))
    emp_nos
    |> Enum.uniq()
    |> List.delete(nil)
    |> List.delete(member_emp_no)
  end

  def get_max_expiry(member) do
    if member.type == "Dependent" do
      member.principal.expiry_date
    else
      get_account_group_end_date(member.account_group)
    end
  end

  def check_mded(vdh, vrd, mded_principal) do
    # vdh = Valid Date Hired
    # vrd = Valid Regularization Date

    case mded_principal do
      "Date of Hire" ->
        if vdh == false, do: "disabled", else: ""
          "Date of Regularization" ->
            if vrd == false, do: "disabled", else: ""
              _ ->
                ""
    end
  end

  def check_mded_status(vdh, vrd, mded_principal) do
    # vdh = Valid Date Hired
    # vrd = Valid Regularization Date
    case mded_principal do
      "Date of Hire" ->
        if vdh == false, do: "(Requires Date of Hire)", else: ""
          "Date of Regularization" ->
            if vrd == false, do: "(Requires Date of Regularization)", else: ""
              _ ->
                ""
    end
  end

  # def render("load_effective_date_by_prod", %{members: member}) do
  # end
  def display_batch_no(authorization_id) do
    batch_authorization = BatchContext.get_batch_authorization_by_auth_id(authorization_id)
    if is_nil(batch_authorization) do
      "N/A"
    else
      batch_authorization.batch.batch_no
    end
  end

  def check_kyc_compliant(member) do
    if is_nil(member.kyc_bank) do
      "Not KYC Compliant"
    else
      "KYC Compliant"
    end
  end

  def valid_acu?(member, product) do
    member_products = for member_product <- member.products, into: [] do
      packages =
        member_product.account_product.product.product_benefits
        |> Enum.map(&(&1.benefit))
        |> check_benefits()
    end

    if Enum.empty?(member_products) do
      ""
    else
      ""
    end
  end

  def get_img_url(member) do
    Innerpeace.ImageUploader
    |> LayoutView.image_url_for(member.photo, member, :original)
    |> String.replace("/apps/payor_link/assets/static", "")
  end
end


