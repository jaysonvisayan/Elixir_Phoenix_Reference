defmodule Innerpeace.PayorLink.Web.Api.V1.AccountView do
  use Innerpeace.PayorLink.Web, :view

  alias Innerpeace.Db.Base.ProductContext

  def render("index.json", %{account_group: account_group}) do
    %{data: render_many(account_group, Innerpeace.PayorLink.Web.Api.V1.AccountView, "all_account_group.json", as: :account_group)}
  end

  def render("show.json", %{account_group: account_group}) do
    %{data: render_one(account_group, Innerpeace.PayorLink.Web.Api.V1.AccountView, "account_group.json", as: :account_group)}
  end

  def render("show_new.json", %{account_group_v2: account_group_v2}) do
   %{data: render_one(account_group_v2, Innerpeace.PayorLink.Web.Api.V1.AccountView, "account_group_v2.json", as: :account_group_v2)}
  end

  def render("all_account_group.json", %{account_group: account_group}) do
    %{
      id: account_group.id,
      name: account_group.name,
      code: account_group.code,
      type: account_group.types,
      description: account_group.description,
      segment: account_group.segment,
      phone_no: account_group.phone_no,
      email: account_group.email,
      remarks: account_group.remarks,
      industry_code: account_group.industry.code,
      account: render_many(
        account_group.account,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "account2.json",
        as: :account
      ),
      account_group_address: render_many(
        account_group.account_group_address,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "account_group_address.json",
        as: :account_group_address
      ),
      contact: render_many(
        account_group.account_group_contacts,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "account_group_contacts.json",
        as: :account_group_contacts
      ),
      # financial: render_one(
      #   account_group.payment_account,
      #   Innerpeace.PayorLink.Web.Api.V1.AccountView,
      #   "financial.json",
      #   as: :financial
      # ),
      hierarchy_of_eligible_dependent: render_many(
        account_group.account_hierarchy_of_eligible_dependents,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "hierarchy_of_eligible_dependent.json",
        as: :hierarchy_of_eligible_dependent
      )
    }
  end

  def render("account2.json", %{account: account}) do
    %{
      start_date: account.start_date,
      end_date: account.end_date,
      status: account.status,
      major_version: account.major_version,
      minor_version: account.minor_version,
      build_version: account.build_version,
      step: account.step,
      products: render_many(
        account.account_products,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "account_product.json",
        as: :account_product
      )
    }
  end

  def render("account_group.json", %{account_group: account_group}) do
    %{
      id: account_group.id,
      name: account_group.name,
      code: account_group.code,
      type: account_group.type,
      description: account_group.description,
      segment: account_group.segment,
      phone_no: account_group.phone_no,
      email: account_group.email,
      remarks: account_group.remarks,
      industry_code: account_group.industry.code,
      original_effective_date: account_group.original_effective_date,
      account: render_many(
        account_group.account,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "account.json",
        as: :account
      ),
      account_group_address: render_many(
        account_group.account_group_address,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "account_group_address.json",
        as: :account_group_address
      ),
      contact: render_many(
        account_group.account_group_contacts,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "account_group_contacts.json",
        as: :account_group_contacts
      ),
      financial: render_one(
        account_group.payment_account,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "financial.json",
        as: :financial
      ),
      products: render_many(
        account_group.account_products,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "account_product.json",
        as: :account_product
      ),
      approvers: render_many(
        account_group.approvers,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "account_group_approval.json",
        as: :account_group_approval
      ),
      hierarchy_of_eligible_dependent: render_many(
        account_group.account_hierarchy_of_eligible_dependents,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "hierarchy_of_eligible_dependent.json",
        as: :hierarchy_of_eligible_dependent
      )
    }
  end

  def render("account_group_v2.json", %{account_group_v2: account_group_v2}) do
    %{
      id: account_group_v2.id,
      name: account_group_v2.name,
      code: account_group_v2.code,
      type: account_group_v2.type,
      segment: account_group_v2.segment,
      phone_no: account_group_v2.phone_no,
      email: account_group_v2.email,
      industry_code: account_group_v2.industry.code,
      original_effective_date: account_group_v2.original_effective_date,
      account: render_many(
        account_group_v2.account,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "account.json",
        as: :account
      ),
      account_group_address: render_many(
        account_group_v2.account_group_address,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "account_group_address.json",
        as: :account_group_address
      ),
      contact: render_many(
        account_group_v2.account_group_contacts,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "account_group_contacts.json",
        as: :account_group_contacts
      ),
      products: render_many(
        account_group_v2.account_products,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "account_product.json",
        as: :account_product
      )
    }
  end

  def render("account.json", %{account: account}) do
    %{
      start_date: account.start_date,
      end_date: account.end_date,
      status: account.status,
      major_version: account.major_version,
      minor_version: account.minor_version,
      build_version: account.build_version,
      step: account.step
    }
  end

  def render("account_group_address.json", %{account_group_address: account_group_address}) do
    %{
      line_1: account_group_address.line_1,
      line_2: account_group_address.line_2,
      postal_code: account_group_address.postal_code,
      city: account_group_address.city,
      country: account_group_address.country,
      type: account_group_address.type,
      province: account_group_address.province,
      is_check: account_group_address.is_check,
      region: account_group_address.region
    }
  end

  def render("account_group_contacts.json", %{account_group_contacts: account_group_contacts}) do
    %{
      type: account_group_contacts.contact.type,
      last_name: account_group_contacts.contact.last_name,
      department: account_group_contacts.contact.department,
      designation: account_group_contacts.contact.designation,
      email: account_group_contacts.contact.email,
      ctc_number: account_group_contacts.contact.ctc,
      ctc_date_issued: account_group_contacts.contact.ctc_date_issued,
      ctc_place_issued: account_group_contacts.contact.ctc_place_issued,
      passport_number: account_group_contacts.contact.passport_no,
      passport_date_issued: account_group_contacts.contact.passport_date_issued,
      contact_number: render_many(
        account_group_contacts.contact.phones,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "contact_phones.json",
        as: :phone
      )
    }
  end

  def render("contact_phones.json", %{phone: phone}) do
    %{
      type: phone.type,
      number: phone.number,
      country_code: phone.country_code,
      area_code: phone.area_code,
      local: phone.local
    }
  end

  def render("financial.json", %{financial: financial}) do
    %{
      bank_account: financial.bank_account,
      mode_of_payment: financial.mode_of_payment,
      account_tin: financial.account_tin,
      vat_status: financial.vat_status,
      p_sched_of_payment: financial.p_sched_of_payment,
      d_sched_of_payment: financial.d_sched_of_payment,
      previous_carrier: financial.previous_carrier,
      attached_point: financial.attached_point,
      revolving_fund: financial.revolving_fund,
      threshold: financial.threshold,
      funding_arrangement: financial.funding_arrangement,
      authority_debit: financial.authority_debit,
      payee_name: financial.payee_name
    }
  end

  def render("account_group_approval.json", %{account_group_approval: account_group_approval}) do
    %{
      name: account_group_approval.name,
      department: account_group_approval.department,
      designation: account_group_approval.designation,
      telephone: account_group_approval.telephone,
      mobile: account_group_approval.mobile,
      email: account_group_approval.email
    }
  end

  def render("account_product.json", %{account_product: account_product}) do
    product = ProductContext.get_product!(account_product.product_id)
    %{
      product_id: account_product.product_id,
      name: account_product.name,
      code: product.code,
      description: account_product.description,
      type: account_product.type,
      limit_applicability: account_product.limit_applicability,
      limit_type: account_product.limit_type,
      limit_amount: account_product.limit_amount,
      status: account_product.status,
      standard_product: account_product.standard_product,
      rank: account_product.rank
    }
  end

  def render("account_group_2.json", %{account_group: account_group}) do
    %{
      id: account_group.id,
      name: account_group.name,
      code: account_group.code,
      account: render_many(
        account_group.account,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "account.json", as: :account
      ),
      members: render_many(
        account_group.members,
        Innerpeace.PayorLink.Web.Api.V1.MemberView,
        "member_account.json",
        as: :member
      ),
      dependent_hierarchy: render_many(
        account_group.account_hierarchy_of_eligible_dependents,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "account_dependent_hierarchy.json",
        as: :dependent_hierarchy
      )
    }
  end

  def render("account_dependent_hierarchy.json", %{dependent_hierarchy: dependent_hierarchy}) do
    %{
      id: dependent_hierarchy.id,
      hierarchy_type: dependent_hierarchy.hierarchy_type,
      dependent: dependent_hierarchy.dependent,
      ranking: dependent_hierarchy.ranking
    }
  end

  def render("hierarchy_of_eligible_dependent.json", %{hierarchy_of_eligible_dependent: hierarchy_of_eligible_dependent}) do
    %{
      hierarchy_type: hierarchy_of_eligible_dependent.hierarchy_type,
      dependent: hierarchy_of_eligible_dependent.dependent,
      ranking: hierarchy_of_eligible_dependent.ranking
    }
  end

  def render("account_latest.json", %{account_group: account_group}) do
    %{
      account_latest: render_many(account_group, Innerpeace.PayorLink.Web.Api.V1.AccountView, "account_latest_list.json", as: :account)
    }
  end

  def render("account_latest_list.json", %{account: account}) do
    dc =
      account.date_created
      |> DateTime.to_date
      |> Date.to_string

    %{
      code: account.code,
      name: account.name,
      date_created: dc
    }
  end

  def render("batch.json", %{accounts: accounts}) do
    success = accounts |> Enum.reject(&(Map.has_key?(&1, :errors)))
    failed = Enum.filter(accounts, &(Map.has_key?(&1, :errors)))
    %{
      success: render_many(success, Innerpeace.PayorLink.Web.Api.V1.AccountView, "success.json", as: :account),
      failed: render_many(failed, Innerpeace.PayorLink.Web.Api.V1.AccountView, "failed_batch.json", as: :account)
    }
  end

  def render("success.json", %{account: account}) do
    %{
      account_code: account.account_group_v2.code,
      product_codes: account.product_codes,
      message: "Successfully added plan/s"
    }
  end

  def render("failed_batch.json", %{account: account}) do
    %{
      params: %{
        account_code: account[:account_code],
        product_codes: account[:product_codes]
      },
      errors: account[:errors]
    }
  end

  def render("create_sap.json", %{account_group: account_group}) do
    %{
      id: account_group.id,
      name: account_group.name,
      segment: account_group.segment,
      industry_code: account_group.industry.code,
      effective_date: account_group.account.start_date,
      expiry_date: account_group.account.end_date,
      original_effective_date: account_group.original_effective_date,
      type: account_group.type,
      phone: account_group.phone_no,
      email: account_group.email,
      account_group_address: render_many(
        account_group.addresses,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "account_group_address2.json",
        as: :account_group_address
      ),
      contacts: render_many(
        account_group.contacts,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "contacts.json",
        as: :contact
      ),
      financial: %{
        tin: account_group.financial.account_tin,
        vat_status: account_group.financial.vat_status,
        previous_carrier: account_group.financial.previous_carrier,
        attached_point: account_group.financial.attached_point,
        payment_mode: account_group.financial.mode_of_payment,
        ####### not yet clarified
        bank_account_number: account_group.financial.bank_account,
        bank_name: account_group.financial.bank_name,
        bank_branch: account_group.financial.bank_branch,
        ####### not yet clarified
        payee_name: account_group.financial.payee_name,
        authority_to_debit: account_group.financial.authority_debit
      },
      personnels: render_many(
        account_group.personnels,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "personnels.json",
        as: :personnel
      )
    }
  end

  def render("get_sap.json", %{account_group: account_group}) do
    %{
      id: account_group.id,
      name: account_group.name,
      segment: account_group.segment,
      industry_code: account_group.industry_code,
      effective_date: transform_date_format(account_group.effectivity_date),
      expiry_date: transform_date_format(account_group.expiry_date),
      original_effective_date: transform_date_format(account_group.original_effective_date),
      type: account_group.type,
      phone: account_group.phone_no,
      email: account_group.email,
      account_group_address: render_many(
        account_group.addresses,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "account_group_address2.json",
        as: :account_group_address
      ),
      contacts: render_many(
        account_group.contacts,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "contacts2.json",
        as: :contact
      ),
      financial: %{
        tin: account_group.financial.account_tin,
        vat_status: account_group.financial.vat_status,
        previous_carrier: account_group.financial.previous_carrier,
        attached_point: account_group.financial.attached_point,
        payment_mode: account_group.financial.mode_of_payment,
        ####### not yet clarified
        bank_account_number: account_group.financial.bank_account,
        bank_name: account_group.financial.bank_name,
        bank_branch: account_group.financial.bank_branch,
        ####### not yet clarified
        payee_name: account_group.financial.payee_name,
        authority_to_debit: account_group.financial.authority_debit
      },
      personnels: render_many(
        account_group.personnels,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "personnels.json",
        as: :personnel
      )
    }
  end

  def render("account_group_address2.json", %{account_group_address: account_group_address}) do
    %{
      type: account_group_address.type,
      line1: account_group_address.line_1,
      line2: account_group_address.line_2,
      city: account_group_address.city,
      province: account_group_address.province,
      region: account_group_address.region,
      country: account_group_address.country,
      postal_code: account_group_address.postal_code,
      is_check: account_group_address.is_check
    }
  end

  def render("contacts.json", %{contact: contact}) do
    %{
      type: contact.type,
      full_name: contact.last_name,
      department: contact.department,
      designation: contact.designation,

      telephone: render_many(
        contact.phones,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "telephones.json",
        as: :telephone
      ),

      mobile: render_many(
        contact.mobiles,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "mobiles.json",
        as: :mobile
      ),

      fax: render_many(
        contact.fax,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "faxes.json",
        as: :fax
      ),

      email: contact.email,
      ctc_number: contact.ctc,
      ctc_date_issued: contact.ctc_date_issued,
      ctc_place_issued: contact.ctc_place_issued,
      passport_number: contact.passport_no,
      passport_date_issued: contact.passport_date_issued,
      passport_place_issued: contact.passport_place_issued
    }
  end

  def render("contacts2.json", %{contact: contact}) do
    %{
      type: contact.type,
      full_name: contact.last_name,
      department: contact.department,
      designation: contact.designation,

      telephone: render_phones(contact.phones, [], "telephone"),
      mobile: render_phones(contact.phones, [], "mobile"),

      fax: render_many(
        contact.fax,
        Innerpeace.PayorLink.Web.Api.V1.AccountView,
        "faxes.json",
        as: :fax
      ),

      email: contact.email,
      ctc_number: contact.ctc,
      ctc_date_issued: contact.ctc_date_issued,
      ctc_place_issued: contact.ctc_place_issued,
      passport_number: contact.passport_no,
      passport_date_issued: contact.passport_date_issued,
      passport_place_issued: contact.passport_place_issued
    }
  end

  defp render_phones([phone | tails], result, type) do
    if phone.type == type do
      render_phones(tails, result ++ [phone.number], type)
    else
      render_phones(tails, result, type)
    end
  end
  defp render_phones([], result, _type), do: result

  def render("telephones.json", %{telephone: telephone}) do
    telephone.number
  end
  def render("mobiles.json", %{mobile: mobile}) do
    mobile.number
  end
  def render("faxes.json", %{fax: fax}) do
    fax.number
  end

  def render("personnels.json", %{personnel: personnel}) do
    %{
      personnel: personnel.personnel,
      specialization: personnel.specialization,
      location: personnel.location,
      schedule: personnel.schedule,
      no_of_personnel: personnel.no_of_personnel,
      payment_of_mode: personnel.payment_of_mode,
      retainer_fee: personnel.retainer_fee,
      amount: personnel.amount
    }
  end

  def render("account_renew.json", %{new_account: new_account}) do
    %{
      step: new_account.step,
      status: new_account.status,
      start_date: new_account.start_date,
      end_date: new_account.end_date,
      major_version: new_account.major_version,
      minor_version: new_account.minor_version,
      build_version: new_account.build_version
    }
  end

  def render("account_cancel.json", %{account: account}) do
    %{
      step: account.step,
      status: account.status,
      start_date: transform_date_format(account.start_date),
      end_date: transform_date_format(account.end_date),
      major_version: account.major_version,
      minor_version: account.minor_version,
      build_version: account.build_version,
      cancellation_date: transform_date_format(account.cancel_date),
      reason: account.cancel_reason,
      remarks: account.cancel_remarks
    }
  end

  def render("account_reactivate.json", %{account: account}) do
    %{
      step: account.step,
      status: account.status,
      start_date: transform_date_format(account.start_date),
      end_date: transform_date_format(account.end_date),
      major_version: account.major_version,
      minor_version: account.minor_version,
      build_version: account.build_version,
      reactivation_date: transform_date_format(account.reactivate_date),
      remarks: account.reactivate_remarks
    }
  end

  defp transform_date_format(date) do #transforms date to MMM-DD-YYYY
    [head | tails] =
      date
      |> Ecto.Date.to_string()
      |> String.split("-")
    date = tails
           |> List.insert_at(2, head)
           |> transform_month()
           |> Enum.join("-")
  end

  defp transform_month([head | tails]) do
    new_head = case head do
      "01" -> "Jan"
      "02" -> "Feb"
      "03" -> "Mar"
      "04" -> "Apr"
      "05" -> "May"
      "06" -> "Jun"
      "07" -> "Jul"
      "08" -> "Aug"
      "09" -> "Sep"
      "10" -> "Oct"
      "11" -> "Nov"
      "12" -> "Dec"
    end
   [new_head | tails]
  end

  def render("account_suspend.json", %{account: account}) do
    %{
      step: account.step,
      status: account.status,
      start_date: transform_date_format(account.start_date),
      end_date: transform_date_format(account.end_date),
      major_version: account.major_version,
      minor_version: account.minor_version,
      build_version: account.build_version,
      remarks: account.suspend_remarks,
      suspension_date: transform_date_format(account.suspend_date),
      reason: account.suspend_reason,
    }
  end

  def render("account_extend.json", %{account: account}) do
    %{
      step: account.step,
      status: account.status,
      start_date: transform_date_format(account.start_date),
      end_date: transform_date_format(account.end_date),
      major_version: account.major_version,
      minor_version: account.minor_version,
      build_version: account.build_version,
      remarks: account.extend_remarks
    }
  end

end
