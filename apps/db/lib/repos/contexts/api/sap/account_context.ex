defmodule Innerpeace.Db.Base.Api.Sap.AccountContext do
  import Ecto.{Query}, warn: false

  @moduledoc :false

  alias Ecto.Changeset
  alias Innerpeace.Db.Base.AccountContext
  alias Innerpeace.Db.{
    Base.Api.UtilityContext,
    Repo,
    Schemas.Account,
    Schemas.AccountGroup,
    Schemas.AccountGroupAddress,
    Schemas.Industry,
    Schemas.AccountGroupContact,
    Schemas.Contact,
    Schemas.Phone,
    Schemas.Fax,
    Schemas.PaymentAccount,
    Schemas.AccountGroupApproval,
    Schemas.AccountGroupPersonnel
  }

  def create(user_id, params) do
    with {:ok, changeset} <- validate_account(params),
         {:ok, account_group} <- insert_account_group(changeset),
         {:ok, account} <- insert_account(account_group.id, changeset, user_id),
         {:ok, addresses} <- insert_account_group_address(account_group.id, changeset),
         {:ok, contacts} <- insert_account_group_contacts(account_group.id, changeset),
         {:ok, financial} <- insert_ag_financial(account_group.id, changeset),
         {:ok, personnels} <- insert_ag_personnel(account_group.id, changeset)
    do
      {
        :ok,
        account_group
        |> Repo.preload([:industry])
        |> Map.put(:account, account)
        |> Map.put(:addresses, addresses)
        |> Map.put(:contacts, contacts)
        |> Map.put(:financial, financial)
        |> Map.put(:personnels, personnels)
      }
    else
      {:error, changeset} ->
        {:error, changeset}
      _ ->
        {:invalid}
    end
  end

  defp validate_account(params) do
    fields = %{
      code: :string,
      segment: :string,
      name: :string,
      type: :string,
      industry_code: :string,
      effective_date: Ecto.Date,
      expiry_date: Ecto.Date,
      original_effective_date: Ecto.Date,
      company_address: :map,
      billing_address: :map,
      is_billing_same_with_company: :boolean,
      contact: {:array, :map},
      financial: :map,
      personnel: {:array, :map},
      phone: :string,
      email: :string
    }
    changeset =
      {%{}, fields}
      |> Changeset.cast(params, Map.keys(fields))
      |> Changeset.validate_required([
        :code,
        :segment,
        :name,
        :type,
        :industry_code,
        :effective_date,
        :expiry_date,
        :original_effective_date,
        :company_address,
        :is_billing_same_with_company,
        :financial,
        :personnel
      ])
      |> validate_code()
      # |> validate_name()
      |> Changeset.validate_length(:name, max: 80)
      |> Changeset.validate_length(:code, max: 80)
      |> validate_industry_code()
      |> validate_account_dates()
      |> validate_addresses(:company_address)
      |> validate_addresses(:billing_address)
      |> validate_contact()
      |> capitalize(:segment)
      |> Changeset.validate_inclusion(:segment, [
        "Corporate",
        "Individual",
        "Family",
        "Group"
      ])
      |> capitalize(:type)
      |> Changeset.validate_inclusion(:type, [
        "Headquarters",
        "Subsidiary",
        "Branch"
      ])
      |> validate_contact_count("corp signatory")
      |> validate_contact_count("contact person")
      |> validate_contact_count("account manager")
      |> validate_contact_count("account officer")
      |> validate_financial()
      |> validate_personnel()
      |> Changeset.validate_length(:personnel, min: 1, message: "at least one is required")
      |> Changeset.validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp capitalize(changeset, key) do
    with true <- Map.has_key?(changeset.changes, key) do
      string =
        changeset.changes[key]
        |> String.split(" ")
        |> Enum.map(&(String.capitalize(&1)))
        |> Enum.join(" ")
      changeset
      |> Changeset.put_change(key, string)
    else
      _ ->
        changeset
    end
  end

  defp validate_code(%{changes: %{code: code}} = changeset) do
    if is_nil(get_account_group_by_code(code)) do
      changeset
    else
      Changeset.add_error(changeset, :code, "is already taken")
    end
  end

  defp validate_code(changeset), do: changeset

  defp validate_name(%{changes: %{name: name}} = changeset) do
    if is_nil(get_account_group_by_name(name)) do
      changeset
    else
      Changeset.add_error(changeset, :name, "is already taken")
    end
  end

  defp validate_name(changeset), do: changeset

  def get_account_group_by_code(code) do
    AccountGroup
    |> where([ag], ag.code == ^code)
    |> select([ag], ag.id)
    |> limit(1)
    |> Repo.one()
  end

  def get_account_group_by_name(name) do
    AccountGroup
    |> where([ag], ag.name == ^name)
    |> select([ag], ag.id)
    |> limit(1)
    |> Repo.one()
  end

  defp validate_industry_code(%{changes: %{industry_code: industry_code}} = changeset) do
    industry = get_indsutry_by_code(industry_code)
    if is_nil(industry) do
      Changeset.add_error(changeset, :industry_code, "is invalid")
    else
      changeset
      |> Changeset.put_change(:industry_id, industry)
    end
  end

  defp validate_industry_code(changeset), do: changeset

  defp get_indsutry_by_code(code) do
    Industry
    |> where([i], i.code == ^code)
    |> limit(1)
    |> select([i], i.id)
    |> Repo.one()
  end

  defp validate_account_dates(%{
    changes: %{
      effective_date: effective_date,
      expiry_date: expiry_date
    }
  } = changeset) do
    date_compare = Ecto.Date.compare(expiry_date, effective_date)
    if date_compare == :lt or date_compare == :eq do
      changeset
      |> Changeset.add_error(:expiry_date, "must be greater than effective Date")
    else
      changeset
    end
  end

  defp validate_account_dates(changeset), do: changeset

  defp validate_addresses(changeset, :billing_address) do
    with true <- Map.has_key?(changeset.changes, :billing_address),
         true <- Map.has_key?(changeset.changes, :is_billing_same_with_company),
         false <- changeset.changes.is_billing_same_with_company,
         {:ok, address_changeset} <- validate_address_params(changeset.changes[:billing_address])
    do
      changeset
    else
      {:error, address_changeset} ->
        errors =
          address_changeset.errors
          |> UtilityContext.changeset_errors_to_string()
        changeset
        |> Changeset.add_error(:billing_address, "(#{errors})")
      _ ->
        changeset
    end
  end

  defp validate_addresses(changeset, key) do
    with true <- Map.has_key?(changeset.changes, key),
         {:ok, address_changeset} <- validate_address_params(changeset.changes[key])
    do
      changeset
    else
      {:error, address_changeset} ->
        errors =
          address_changeset.errors
          |> UtilityContext.changeset_errors_to_string()
        changeset
        |> Changeset.add_error(key, "(#{errors})")
      _ ->
        changeset
    end
  end

  defp validate_address_params(params) do
    fields = %{
      line1: :string,
      line2: :string,
      city: :string,
      province: :string,
      region: :string,
      country: :string,
      postal_code: :integer
    }
    changeset =
      {%{}, fields}
      |> Changeset.cast(params, Map.keys(fields))
      |> Changeset.validate_required([
        :line1,
        :line2,
        :city,
        :province,
        :region,
        :postal_code
      ])
      |> Changeset.validate_length(:line1, max: 150)
      |> Changeset.validate_length(:line2, max: 150)
      |> Changeset.put_change(:country, "Philippines")
      |> Changeset.validate_number(:postal_code, less_than_or_equal_to: 99999, message: "maximum of 5 numeric characters")

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp validate_contact(%{changes: %{contact: contact}} = changeset) do
    checker =
      contact
      |> Enum.with_index(1)
      |> validate_contact_params([])
      |> Enum.join(", ")
    if checker == "" do
      changeset
    else
      changeset
      |> Changeset.add_error(:contact, checker)
    end
  end

  defp validate_contact(changeset), do: changeset

  defp validate_contact_params([{params, index} | tails], errors) do
    fields = %{
      type: :string,
      name: :string,
      department: :string,
      designation: :string,
      telephone: {:array, :string},
      mobile: {:array, :string},
      fax: {:array, :string},
      email: :string,
      ctc_number: :string,
      ctc_date_issued: Ecto.Date,
      ctc_place_issued: :string,
      passport_number: :string,
      passport_date_issued: Ecto.Date,
      passport_place_issued: :string
    }
    changeset =
      {%{}, fields}
      |> Changeset.cast(params, Map.keys(fields))
      |> Changeset.validate_required([
        :type,
        :name,
        :email,
        :mobile
      ])
      |> capitalize(:type)
      |> Changeset.validate_inclusion(:type, [
        "Contact Person",
        "Corp Signatory",
        "Account Manager",
        "Account Officer",
        "Company Contact"
      ])
      |> Changeset.validate_length(:name, max: 80)
      |> Changeset.validate_format(:name, ~r/^[a-zA-Z .,-]*$/, message: "has invalid format")
      |> Changeset.validate_length(:department, max: 80)
      |> Changeset.validate_format(:department, ~r/^[a-zA-Z0-9 .,-]*$/, message: "has invalid format")
      |> Changeset.validate_length(:designation, max: 80)
      |> Changeset.validate_format(:designation, ~r/^[a-zA-Z0-9 .,-]*$/, message: "has invalid format")
      |> Changeset.validate_length(:mobile, min: 1)
      |> Changeset.validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
      |> Changeset.validate_length(:mobile, min: 1)
      |> Changeset.validate_format(:ctc_number, ~r/^[a-zA-Z0-9 ]*$/, message: "has invalid format")
      |> Changeset.validate_length(:ctc_number, max: 80)
      |> Changeset.validate_length(:ctc_place_issued, max: 80)
      |> Changeset.validate_length(:passport_number, max: 80)
      |> Changeset.validate_length(:passport_place_issued, max: 80)
      |> validate_mobile()
      |> validate_telephone()
      |> validate_fax()

    if changeset.valid? do
      validate_contact_params(tails, errors)
    else
      changeset_errors = UtilityContext.changeset_errors_to_string(changeset.errors)
      errors = errors ++ ["row #{index} errors (#{changeset_errors})"]
      validate_contact_params(tails, errors)
    end
  end

  defp validate_contact_params([], errors), do: errors

  defp validate_mobile(%{changes: %{mobile: mobile}} = changeset) do
    checker =
      mobile
      |> Enum.with_index(1)
      |> validate_mobile_params([])
      |> Enum.join(", ")
    if checker == "" do
      changeset
    else
      changeset
      |> Changeset.add_error(:mobile, "row #{checker} is invalid")
    end
  end

  defp validate_mobile(changeset), do: changeset

  defp validate_mobile_params([{mobile, index} | tails], errors) do
    if String.length(mobile) == 10 do
      String.to_integer(mobile)
      validate_mobile_params(tails, errors)
    else
      errors = errors ++ [index]
      validate_mobile_params(tails, errors)
    end
    rescue
      _ ->
        errors = errors ++ [index]
        validate_mobile_params(tails, errors)
  end

  defp validate_mobile_params([], errors), do: errors

  defp validate_telephone(%{changes: %{telephone: telephone}} = changeset) do
    checker =
      telephone
      |> Enum.with_index(1)
      |> validate_telephone_params([])
      |> Enum.join(", ")
    if checker == "" do
      changeset
    else
      changeset
      |> Changeset.add_error(:telephone, "row #{checker} is invalid")
    end
  end

  defp validate_telephone(changeset), do: changeset

  defp validate_telephone_params([{telephone, index} | tails], errors) do
    with [area, number, local] <- String.split(telephone, "-"),
         true <- String.length(area) > 0 and String.length(area) < 7,
         true <- String.length(number) == 7,
         true <- String.length(local) > 0 and String.length(local) < 4
    do
      validate_telephone_params(tails, errors)
    else
      _ ->
      errors = errors ++ [index]
      validate_telephone_params(tails, errors)
    end
  end

  defp validate_telephone_params([], errors), do: errors

  defp validate_fax(%{changes: %{fax: fax}} = changeset) do
    checker =
      fax
      |> Enum.with_index(1)
      |> validate_fax_params([])
      |> Enum.join(", ")
    if checker == "" do
      changeset
    else
      changeset
      |> Changeset.add_error(:fax, "row #{checker} is invalid")
    end
  end

  defp validate_fax(changeset), do: changeset

  defp validate_fax_params([{fax, index} | tails], errors) do
    with [area, number, local] <- String.split(fax, "-"),
         true <- String.length(area) > 0 and String.length(area) < 7,
         true <- String.length(number) == 7,
         true <- String.length(local) > 0 and String.length(local) < 4
    do
      validate_fax_params(tails, errors)
    else
      _ ->
      errors = errors ++ [index]
      validate_fax_params(tails, errors)
    end
  end

  defp validate_fax_params([], errors), do: errors

  defp validate_contact_count(%{
    changes: %{
      contact: contact}} = changeset,
      type
  ) do
    count =
      changeset.changes.contact
      |> Enum.filter(fn(contact) ->
        String.downcase(contact["type"] || "") == type
      end)
      |> Enum.count()
    if count > 0 do
      changeset
    else
      changeset
      |> Changeset.add_error(:contact, "at least one corp signatory is required")
    end
  end

  defp validate_contact_count(changeset, _key), do: changeset

  defp validate_financial(%{changes: %{financial: financial}} = changeset) do
    fields = %{
      tin: :string,
      vat_status: :string,
      previous_carrier: :string,
      attatched_point: :string,
      payment_mode: :string,
      bank_account_number: :string,
      bank_name: :string,
      bank_branch: :string,
      payee_name: :string,
      authority_to_debit: :boolean,
      special_approval: :map,
      is_funding_source: :boolean
    }
    financial_changeset =
      {%{}, fields}
      |> Changeset.cast(financial, Map.keys(fields))
      |> Changeset.validate_required([
        :tin,
        :vat_status,
        :payment_mode
      ])
      |> Changeset.validate_inclusion(:vat_status, [
        "20% VAT-able",
        "Fully VAT-able",
        "Others",
        "VAT Exempt",
        "Zero-Rated"
      ])
      |> Changeset.validate_length(:tin, is: 12, message: "should be 12")
      |> Changeset.validate_length(:previous_carrier, max: 80)
      |> Changeset.validate_length(:attatched_point, max: 12)
      |> capitalize(:payment_mode)
      |> Changeset.validate_inclusion(:payment_mode, [
        "Check",
        "Electronic Debit"
      ])
      |> validate_payment_mode()
      |> validate_special_approval()

    if financial_changeset.valid? do
      changeset
    else
      errors =
        financial_changeset.errors
        |> UtilityContext.changeset_errors_to_string()
      changeset
      |> Changeset.add_error(:financial, "(#{errors})")
    end
  end

  defp validate_financial(changeset), do: changeset

  defp validate_payment_mode(%{changes: %{payment_mode: payment_mode}} = changeset) do
    if payment_mode == "Check" do
      changeset
      |> Changeset.validate_required(:payee_name)
    else
      changeset
      |> Changeset.validate_required([
        :bank_name,
        :bank_account_number,
        :bank_branch,
        :authority_to_debit
      ])
    end
  end

  defp validate_payment_mode(changeset), do: changeset

  defp validate_special_approval(%{
    changes: %{
      special_approval: special_approval,
      is_funding_source: false
    }
  } = changeset) do
    fields = %{
      payment_mode: :string,
      bank_account_number: :string,
      bank_name: :string,
      bank_branch: :string,
      payee_name: :string,
      authority_to_debit: :boolean
    }
    special_approval_changeset =
      {%{}, fields}
      |> Changeset.cast(special_approval, Map.keys(fields))
      |> Changeset.validate_required([
        :payment_mode
      ])
      |> capitalize(:payment_mode)
      |> Changeset.validate_inclusion(:payment_mode, [
        "Check",
        "Electronic Debit"
      ])
      |> validate_payment_mode()

    if special_approval_changeset.valid? do
      changeset
    else
      errors =
        special_approval_changeset.errors
        |> UtilityContext.changeset_errors_to_string()
      changeset
      |> Changeset.add_error(:special_approval, "(#{errors})")
    end
  end

  defp validate_special_approval(changeset), do: changeset

  defp validate_personnel(%{changes: %{personnel: personnel}} = changeset) do
    checker =
      personnel
      |> Enum.with_index(1)
      |> validate_personnel_params([])
      |> Enum.join(", ")
    if checker == "" do
      changeset
    else
      changeset
      |> Changeset.add_error(:personnel, "#{checker}")
    end
  end

  defp validate_personnel(changeset), do: changeset

  defp validate_personnel_params([{params, index} | tails], errors) do
    fields = %{
      personnel: :string,
      specialization: :string,
      location: :string,
      schedule: :string,
      no_of_personnel: :integer,
      payment_of_mode: :string,
      retainer_fee: :string,
      amount: :integer
    }
    changeset =
      {%{}, fields}
      |> Changeset.cast(params, Map.keys(fields))
      |> Changeset.validate_required([
        :personnel,
        :specialization,
        :location,
        :schedule,
        :no_of_personnel,
        :payment_of_mode,
        :retainer_fee,
        :amount
      ])
      |> capitalize(:payment_of_mode)
      |> Changeset.validate_inclusion(:payment_of_mode, [
        "Annual",
        "Daily",
        "Hourly",
        "Monthly",
        "Quarterly",
        "Semi-annual",
        "Weekly"
      ])
      |> Changeset.validate_inclusion(:retainer_fee, [
        "Builtin",
        "Charge to ASO",
        "Separate Fee"
      ])
      |> Changeset.validate_length(:personnel, max: 80)
      |> Changeset.validate_length(:specialization, max: 80)
      |> Changeset.validate_length(:location, max: 80)
      |> Changeset.validate_length(:schedule, max: 80)
      |> Changeset.validate_number(:no_of_personnel, less_than_or_equal_to: 9_999_999, message: "maximum of 8 numeric characters")
      |> Changeset.validate_number(:amount, less_than_or_equal_to: 99_999_999, message: "maximum of 8 numeric characters")

    if changeset.valid? do
      validate_personnel_params(tails, errors)
    else
      changeset_errors = UtilityContext.changeset_errors_to_string(changeset.errors)
      errors = errors ++ ["row #{index} errors (#{changeset_errors})"]
      validate_personnel_params(tails, errors)
    end
  end

  defp validate_personnel_params([], errors), do: errors

  defp insert_account_group(changeset) do
    params = setup_account_group_params(changeset)
    %AccountGroup{}
    |> AccountGroup.changeset_sap(params)
    |> Repo.insert()
  end

  defp setup_account_group_params(changeset) do
    %{
      name: Changeset.get_change(changeset, :name),
      code: Changeset.get_change(changeset, :code),
      segment: Changeset.get_change(changeset, :segment),
      type: Changeset.get_change(changeset, :type),
      industry_id: Changeset.get_change(changeset, :industry_id),
      original_effective_date: Changeset.get_change(changeset, :original_effective_date),
      phone_no: Changeset.get_change(changeset, :phone),
      email: Changeset.get_change(changeset, :email)
    }
    |> Map.merge(setup_special_approval(changeset))
  end

  defp setup_special_approval(%{
    changes: %{
      financial: %{
        "is_funding_source" => true
      }
    }
  } = changeset) do
    financial = Changeset.get_change(changeset, :financial)
    %{
      # mode_of_payment: financial["payment_mode"],
      payee_name: financial["payee_name"],
      account_no: financial["bank_account_number"],
      account_name: financial["bank_name"],
      branch: financial["bank_branch"]
    }
  end

  defp setup_special_approval(%{
    changes: %{
      financial: %{
        "special_approval" => special_approval
      }
    }
  } = changeset) do
    %{
      # mode_of_payment: special_approval["payment_mode"],
      payee_name: special_approval["payee_name"],
      account_no: special_approval["bank_account_number"],
      account_name: special_approval["bank_name"],
      branch: special_approval["bank_branch"]
    }
  end

  defp setup_special_approval(changeset) do
    %{}
  end

  defp insert_account(ag_id, changeset, user_id) do
    params = setup_account_params(ag_id, changeset, user_id)
    %Account{}
    |> Account.changeset(params)
    |> Repo.insert()
  end

  defp setup_account_params(ag_id, changeset, user_id) do
    %{
      account_group_id: ag_id,
      start_date: Changeset.get_change(changeset, :effective_date),
      end_date: Changeset.get_change(changeset, :expiry_date),
      status: "Active",
      created_by: user_id,
      updated_by: user_id,
      step: 7,
      major_version: 1,
      minor_version: 0,
      build_version: 0
    }
  end

  defp insert_account_group_address(ag_id, %{
    changes: %{
      is_billing_same_with_company: true
    }
  } = changeset) do
    params = Changeset.get_change(changeset, :company_address)
    {
      :ok,
      [
        insert_address(ag_id, params, "Account Address"),
        insert_address(ag_id, params, "Billing Address")
      ]
    }
  end

  defp insert_account_group_address(ag_id, %{
    changes: %{
      is_billing_same_with_company: false
    }
  } = changeset) do
    account_params = Changeset.get_change(changeset, :company_address)
    billing_params = Changeset.get_change(changeset, :billing_address)
    {
      :ok,
      [
        insert_address(ag_id, account_params, "Account Address"),
        insert_address(ag_id, billing_params, "Billing Address")
      ]
    }
  end

  defp insert_account_group_address(ag_id, changeset), do: {:ok, []}

  defp insert_address(ag_id, params, type) do
    params = setup_address_params(params, ag_id, type)
    %AccountGroupAddress{}
    |> AccountGroupAddress.changeset(params)
    |> Repo.insert!()
  end

  defp setup_address_params(params, ag_id, type) do
    %{
      account_group_id: ag_id,
      line_1: params["line1"],
      line_2: params["line2"],
      city: params["city"],
      province: params["province"],
      region: params["region"],
      country: "Philippines",
      postal_code: params["postal_code"],
      type: type
    }
  end

  defp insert_account_group_contacts(ag_id, %{
    changes: %{
      contact: contact
    }
  } = changeset) do
    contact =
      contact
      |> insert_account_group_contact(ag_id, [])
    {:ok, contact}
  end

  defp insert_account_group_contacts(ag_id, changeset), do: {:ok, []}

  defp insert_account_group_contact([params | tails], ag_id, inserted) do
    with contact_params <- setup_contact_params(params),
         contact <- insert_contact(contact_params),
         contact_phones <- insert_contact_phones([], contact.id, params["telephone"]),
         contact_mobiles <- insert_contact_mobiles([], contact.id, params["mobile"]),
         contact_fax <- insert_contact_fax([], contact.id, params["fax"])
    do
      %AccountGroupContact{}
      |> AccountGroupContact.changeset(%{
        account_group_id: ag_id,
        contact_id: contact.id
      })
      |> Repo.insert()
      contact =
        contact
        |> Map.put(:phones, contact_phones)
        |> Map.put(:mobiles, contact_mobiles)
        |> Map.put(:fax, contact_fax)
      insert_account_group_contact(tails, ag_id, inserted ++ [contact])
    else
      _ ->
        {:ok, []}
    end
  end

  defp insert_account_group_contact([], ag_id, inserted), do: inserted

  defp ag_contact_params(ag_id, params) do
    # contact =
  end

  defp setup_contact_params(params) do
    %{
      first_name: params["full_name"],
      last_name: params["full_name"],
      department: params["department"],
      designation: params["designation"],
      email: params["email"],
      ctc: params["ctc_number"],
      ctc_date_issued: params["ctc_date_issued"],
      ctc_place_issued: params["ctc_place_issued"],
      passport_no: params["passport_number"],
      passport_date_issued: params["passport_date_issued"],
      passport_place_issued: params["passport_place_issued"],
      type: params["type"]
    }
  end

  defp insert_contact(params) do
    %Contact{}
    |> Contact.changeset(params)
    |> Repo.insert!()
  end

  defp insert_contact_phones(phones, contact_id, [phone | tails]) do
    [area, number, local] = String.split(phone, "-")
    params = %{
      contact_id: contact_id,
      area_code: area,
      number: number,
      local: local,
      type: "telephone"
    }
    phone =
      %Phone{}
      |> Phone.changeset_sap(params)
      |> Repo.insert!()
    phones = phones ++ [phone]
    insert_contact_phones(phones, contact_id, tails)
  end

  defp insert_contact_phones(phones, _contact_id, []), do: phones
  defp insert_contact_phones(phones, _contact_id, nil), do: []

  defp insert_contact_mobiles(mobiles, contact_id, [mobile | tails]) do
    params = %{
      contact_id: contact_id,
      number: mobile,
      type: "mobile"
    }
    mobile =
      %Phone{}
      |> Phone.changeset_sap(params)
      |> Repo.insert!()
    mobiles = mobiles ++ [mobile]
    insert_contact_mobiles(mobiles, contact_id, tails)
  end

  defp insert_contact_mobiles(mobiles, _contact_id, []), do: mobiles
  defp insert_contact_mobiles(mobiles, _contact_id, nil), do: []

  defp insert_contact_fax(faxs, contact_id, [fax | tails]) do
    [area, number, local] = String.split(fax, "-")
    params = %{
      contact_id: contact_id,
      number: number,
      prefix: local
    }
    fax =
      %Fax{}
      |> Fax.changeset(params)
      |> Repo.insert!()
    faxs = faxs ++ [fax]
    insert_contact_fax(faxs, contact_id, tails)
  end

  defp insert_contact_fax(faxs, _contact_id, []), do: faxs
  defp insert_contact_fax(_faxs, _contact_id, nil), do: []

  defp insert_ag_financial(ag_id, %{
    changes: %{financial: financial_param}
  })
  do
    params = setup_financial_params(ag_id, financial_param)
    {
      :ok,
      %PaymentAccount{}
      |> PaymentAccount.changeset_account_v2(params)
      |> Repo.insert!()
    }
  end

  defp insert_ag_financial(ag_id, changeset), do: {:ok, %{}}

  defp setup_financial_params(ag_id, params) do
    %{
      account_group_id: ag_id,
      account_tin: params["tin"],
      vat_status: params["vat_status"],
      previous_carrier: params["previous_carrier"],
      mode_of_payment: params["payment_mode"],
      bank_account: params["bank_account_number"],
      bank_name: params["bank_name"],
      bank_branch: params["bank_branch"],
      payee_name: params["payee_name"],
      authority_debit: params["authority_to_debit"],
      attached_point: params["attached_point"]
    }
  end

  defp insert_ag_personnel(ag_id, %{
    changes: %{
      personnel: personnel
    }
  } = changeset) do
    {
      :ok,
      insert_personnel(personnel, ag_id, [])
    }
  end

  defp insert_ag_personnel(ag_id, changeset), do: {:ok, []}

  defp insert_personnel([params | tails], ag_id, inserted) do
    params = setup_personnel_params(ag_id, params)
    agp =
      %AccountGroupPersonnel{}
      |> AccountGroupPersonnel.changeset(params)
      |> Repo.insert!()
    inserted = inserted ++ [agp]
    insert_personnel(tails, ag_id, inserted)
  end

  defp insert_personnel([], ag_id, inserted), do: inserted

  defp setup_personnel_params(ag_id, params) do
    %{
      account_group_id: ag_id,
      personnel: params["personnel"],
      specialization: params["specialization"],
      location: params["location"],
      schedule: params["schedule"],
      no_of_personnel: params["no_of_personnel"],
      payment_of_mode: params["payment_of_mode"],
      retainer_fee: params["retainer_fee"],
      amount: params["amount"]
    }
  end

  def valid_params?(:cancel_account, params) do
    fields = %{
      code: :string,
      effectivity_date: :string,
      expiry_date: :string,
      cancellation_date: :string,
      reason: :string,
      remarks: :string,
      version: :string,
      created_by: :string,
      updated_by: :string
    }
    changeset =
      {%{}, fields}
      |> Changeset.cast(params, Map.keys(fields))
      |> Changeset.validate_required([:reason], message: "Enter reason")
      |> Changeset.validate_required([:effectivity_date], message: "Enter effectivity date")
      |> Changeset.validate_required([:expiry_date], message: "Enter expiry date")
      |> Changeset.validate_required([:cancellation_date], message: "Enter cancellation date")
      |> Changeset.validate_required([:version], message: "Enter version")
      |> Changeset.validate_required([:code], message: "Enter account code")
      |> Changeset.validate_inclusion(:reason, ["Test1", "Test2", "Test3"], message: "Reason is invalid")
      |> Changeset.validate_length(:remarks, max: 255, message: "Must not exceed 255 characters")
      |> validate_all_date_format(:cancel)
      |> transform_date(:cancel)
      |> validate_cancel_date(:cancel)
      |> validate_account(:cancel)
      |> is_cancelled_account?()
  end

  defp is_cancelled_account?({changeset, {:ok, %Account{} = account}}), do: {:ok, account}
  defp is_cancelled_account?(changeset), do: {:error, changeset}

  defp validate_all_date_format(changeset, :cancel) do
    changeset
    |> check_if_has_key?(:effectivity_date)
    |> check_if_has_key?(:expiry_date)
    |> check_if_has_key?(:cancellation_date)
  end

  defp check_if_has_key?(changeset, :effectivity_date = key) do
    if Map.has_key?(changeset.changes, key) do
      changeset =
        changeset
        |> validate_date_format(changeset.changes.effectivity_date, key)
    else
      changeset
    end
  end

  defp check_if_has_key?(changeset, :expiry_date = key) do
    if Map.has_key?(changeset.changes, key) do
      changeset =
        changeset
        |> validate_date_format(changeset.changes.expiry_date, key)
    else
      changeset
    end
  end

  defp check_if_has_key?(changeset, :cancellation_date = key) do
    if Map.has_key?(changeset.changes, key) do
      changeset =
        changeset
        |> validate_date_format(changeset.changes.cancellation_date, key)
    else
      changeset
    end
  end

  defp check_if_has_key?(changeset, :reactivation_date = key) do
    if Map.has_key?(changeset.changes, key) do
      changeset =
        changeset
        |> validate_date_format(changeset.changes.reactivation_date, key)
    else
      changeset
    end
  end

  def validate_date_format(changeset, date, key) do
    bool = valid_format(date)
    with true <- bool do
      case Timex.parse(date, "{Mshort}-{0D}-{YYYY}") do
        {:ok, _} ->
          changeset
        _ ->
          changeset =
            changeset
            |> Changeset.add_error(key, "Invalid date format!")
      end
    else
      false ->
        changeset =
          changeset
          |> Changeset.add_error(key, "Invalid date format!")
    end
  end

  defp validate_account(changeset, :cancel) do
    if changeset.valid? do
      changeset
      |> validate_account_code(:cancel)
      |> find_account_for_renewal(changeset)
      |> validate_version(changeset, :cancel)
      |> validate_start_date(changeset)
      |> validate_end_date()
      |> vaildate_status_account(changeset, :cancel)
    else
      changeset
    end
  end

  defp validate_start_date(%Account{} = account, changeset) do
    start_date =
      account.start_date
      |> Ecto.Date.to_iso8601()
      |> Date.from_iso8601!()

    {:ok, eff_date} =
      changeset.changes.effectivity_date
      |> Timex.parse("{0M}/{D}/{YYYY}")
    if Date.compare(start_date, eff_date) == :eq do
      {changeset, account}
    else
      {Changeset.add_error(changeset,
                          :effectivity_date,
                          "Not equal to account effectivity_date"), account}
    end
  end

  defp validate_start_date(changeset, _), do: changeset

  defp validate_end_date({changeset, account}) do
    end_date =
      account.end_date
      |> Ecto.Date.to_iso8601()
      |> Date.from_iso8601!()

    {:ok, exp_date} =
      changeset.changes.expiry_date
      |> Timex.parse("{0M}/{D}/{YYYY}")

    if Date.compare(end_date, exp_date) == :eq do
      if changeset.valid? do
          account
      else
        changeset
      end
    else
      Changeset.add_error(changeset,
                          :expiry_date,
                          "Not equal to account expiry_date")
    end
  end
  defp validate_end_date(changeset), do: changeset

  defp validate_cancel_date(changeset, :cancel) do
    if changeset.valid? do
      {:ok, date} =
        changeset.changes.cancellation_date
        |> Timex.parse("{0M}/{D}/{YYYY}")
        if Date.compare(date, Date.utc_today()) == :gt do
          {:ok, date} =  Ecto.Date.cast(date)
          changeset
          |> Changeset.put_change(:cancel_date, date)
          |> Changeset.put_change(:cancel_reason, changeset.changes.reason)
          |> check_remarks(:cancel)
        else
          Changeset.add_error(changeset,
                              :cancellation_date,
                              "Should be future dated.")
        end
    else
      changeset
    end
  end

  defp check_remarks(changeset, :cancel) do
    if Map.has_key?(changeset.changes, :remarks) do
      changeset
      |> Changeset.put_change(:cancel_remarks, changeset.changes.remarks)
    else
      changeset
    end
  end

  defp vaildate_status_account(%Account{} = accounts, changeset, :cancel) do
    if accounts.status == "Active" or accounts.status == "Suspended" do
      if is_nil(accounts.suspend_date) and
         # is_nil(accounts.reactivation_date) and
         is_nil(accounts.reactivate_date) do
           accounts
          |> check_if_date_lapse(changeset)
      else
        keys = [:suspend_date, :reactivate_date]
               |> Enum.map(fn(key) ->
                 accounts
                 |> check_if_future_dated(changeset, key)

               end)
               |> check_errors_in_date(accounts)
               |> check_if_date_lapse(changeset)
      end
    else
      Changeset.add_error(changeset,
                          :code,
                          "Account can't be cancelled: status should be Active or Suspended.")
    end
  end

  defp vaildate_status_account(changeset, _, :cancel), do: changeset

  defp update_account_status(%Account{} = account, changeset) do
    account =
      account
      |> Account.changeset_cancel_sap_api(changeset.changes)
      |> Repo.update()

    {changeset, account}
  end

  defp check_if_date_lapse(%Account{} = account, changeset) do
    exp_date =
      account.end_date
      |> Ecto.Date.to_iso8601()
      |> Date.from_iso8601!()

    {:ok, can_date} =
      changeset.changes.cancellation_date
      |> Timex.parse("{0M}/{D}/{YYYY}")

    if Date.compare(can_date, exp_date) == :lt do
      update_account_status(account, changeset)
    else
      Changeset.add_error(changeset,
                          :cancellation_date,
                          "Should be less than account's expiry date.")
    end
  end

  defp check_if_date_lapse(changeset, _changeset), do: changeset

  defp check_if_future_dated(account, changeset, :suspend_date) do
    if check_if_future_dated(account.suspend_date) do
      account
    else
      Changeset.add_error(changeset,
                          :code,
                          "Account can't be cancelled: future dated suspend.")
    end
  end

  defp check_if_future_dated(account, changeset, :reactivate_date) do
    if check_if_future_dated(account.reactivate_date) do
      account
    else
      Changeset.add_error(changeset,
                          :code,
                          "Account can't be cancelled: future dated reactivate.")
    end
  end

  defp check_if_future_dated_suspend(account, changeset, :suspend_date) do
    if check_if_future_dated(account.suspend_date) do
      account
    else
      Changeset.add_error(changeset,
                          :code,
                          "Account can't be suspended: future dated suspend.")
    end
  end

  defp check_if_future_dated_suspend(account, changeset, :cancel_date) do
    if check_if_future_dated(account.cancel_date) do
      account
    else
      Changeset.add_error(changeset,
                          :code,
                          "Account can't be suspended: future dated cancel.")
    end
  end

  defp check_errors_in_date([%Account{}, %Account{}] = result, account), do: account
  defp check_errors_in_date([changeset, %Account{}], _account), do: changeset
  defp check_errors_in_date([%Account{}, changeset], _account), do: changeset
  defp check_errors_in_date(changeset, _account) do
    merge_changeset_errors(changeset, List.first(changeset))
  end

  defp check_if_future_dated(nil), do: true
  defp check_if_future_dated(date) do
    if Ecto.Date.compare(date, Ecto.Date.utc()) == :lt do
      true
    else
      false
    end
  end

  defp valid_format(date) do
    date_array = String.split(date, "-")
    with true <- String.length(Enum.at(date_array, 0)) == 3,
         true <- String.length(Enum.at(date_array, 1)) == 2,
         true <- String.length(Enum.at(date_array, 2)) == 4
    do
      true
    else
      false ->
        false
    end
  end

  defp validate_version(accounts, changeset, :cancel) when is_list(accounts) do
    version = changeset.changes.version
              |> find_account_version(accounts, changeset)
  end
  defp validate_version(changeset, _changeset, :cancel), do: changeset

  defp validate_version(accounts, changeset, :reactivate) do
    if Enum.empty?(accounts) do
      Changeset.add_error(changeset, :code, "Account code does not exist.")
    else
      version = changeset.changes.version
                |> find_account_version(accounts, changeset)
    end
  end

  defp find_account_for_renewal(accounts, changeset) do
    if Enum.empty?(accounts) do
      Changeset.add_error(changeset, :code, "Account code does not exist.")
    else
      acc = Enum.map(accounts, fn(account) ->
        if account.status == "For Activation" or account.status == "For Renewal" do
          account
        end
      end)
      |> Enum.uniq
      |> List.delete(nil)
      if Enum.empty?(acc) do
        accounts
      else
        Changeset.add_error(changeset, :code, "Account has future renewal date.")
      end
    end
  end

  defp find_account_version(version, accounts, changeset) do
    acc = Enum.map(accounts, fn(account) ->
      account_ver = transform_account_version(account)
      if "#{account_ver}" == version do
        account
      end
    end)
    |> Enum.uniq
    |> List.delete(nil)
    if is_nil(List.first(acc)) do
      Changeset.add_error(changeset, :version, "Account version does not exist.")
    else
      List.first(acc)
    end
  end

  defp validate_account_code(changeset, :cancel) do
    Account
    |> join(:inner, [a], ag in AccountGroup, a.account_group_id == ag.id)
    |> where([a, ag], ag.code == ^changeset.changes.code)
    |> Repo.all()
  end

  defp transform_account_version(account) do
    version = [account.major_version, account.minor_version, account.build_version]
              |> Enum.join(".")
  end

  defp merge_changeset_errors([head|tails], changeset), do: merge_changeset_errors(tails, Changeset.merge(changeset, head))
  defp merge_changeset_errors([], changeset), do: changeset

  def valid_params?(:reactivate_account, params) do
    fields = %{
      code: :string,
      effectivity_date: :string,
      expiry_date: :string,
      reactivation_date: :string,
      remarks: :string,
      version: :string,
      created_by: :string,
      updated_by: :string
    }
    changeset =
      {%{}, fields}
      |> Changeset.cast(params, Map.keys(fields))
      |> Changeset.validate_required([:effectivity_date], message: "Enter effectivity date")
      |> Changeset.validate_required([:expiry_date], message: "Enter expiry date")
      |> Changeset.validate_required([:reactivation_date], message: "Enter reactivation date")
      |> Changeset.validate_required([:version], message: "Enter version")
      |> Changeset.validate_required([:code], message: "Enter Account code")
      |> Changeset.validate_length(:remarks, max: 255, message: "Must not exceed 255 characters")
      |> validate_all_date_format(:reactivate)
      |> transform_date(:reactivate)
      |> validate_reactivation_date(:reactivate)
      |> validate_account(:reactivate)
      |> is_cancelled_account?()
  end

  defp validate_all_date_format(changeset, :reactivate) do
    changeset
    |> check_if_has_key?(:effectivity_date)
    |> check_if_has_key?(:expiry_date)
    |> check_if_has_key?(:reactivation_date)
  end

  defp validate_reactivation_date(changeset, :reactivate) do
    if changeset.valid? do
      {:ok, date} =
        changeset.changes.reactivation_date
        |> Timex.parse("{0M}/{D}/{YYYY}")
        if Date.compare(date, Date.utc_today()) == :gt do
          {:ok, date} =  Ecto.Date.cast(date)
          changeset
          |> Changeset.put_change(:reactivate_date, date)
          |> check_remarks(:reactivate)
        else
          Changeset.add_error(changeset,
                              :reactivation_date,
                              "Should be future dated.")
        end
    else
      changeset
    end
  end

  defp check_remarks(changeset, :reactivate) do
    if Map.has_key?(changeset.changes, :remarks) do
      changeset
      |> Changeset.put_change(:reactivate_remarks, changeset.changes.remarks)
    else
      changeset
    end
  end

  defp validate_account(changeset, :reactivate) do
    if changeset.valid? do
      changeset
      |> validate_account_code(:cancel)
      |> validate_version(changeset, :reactivate)
      |> validate_start_date(changeset)
      |> validate_end_date()
      |> vaildate_status_account(changeset, :reactivate)
    else
      changeset
    end
  end

  defp vaildate_status_account(%Account{} = accounts, changeset, :reactivate) do
    if accounts.status == "Suspended" do
      if is_nil(accounts.cancel_date) do
        accounts
        |> validate_expiry_suspend_date(changeset)
      else
        accounts
        |> validate_cancel_suspend_date(changeset)
      end
    else
      Changeset.add_error(changeset,
                          :code,
                          "Account can't be reactivated: status should be Suspended.")
    end
  end

  defp vaildate_status_account(changeset, _, :reactivate), do: changeset

  defp check_if_future_dated(account, changeset, :cancel_date) do
    if check_if_future_dated(account.reactivate_date) do
      account
    else
      Changeset.add_error(changeset,
                          :code,
                          "Account can't be reactivated: future dated reactivate.")
    end
  end

  defp validate_cancel_suspend_date(%Account{} = account, changeset) do
    cancel_date =
      account.cancel_date
      |> Ecto.Date.to_iso8601()
      |> Date.from_iso8601!()

    {:ok, reactivate_date} =
      changeset.changes.reactivation_date
      |> Timex.parse("{0M}/{D}/{YYYY}")

    if Date.compare(reactivate_date, cancel_date) == :lt do
      account
      |> validate_expiry_suspend_date(changeset)
    else
      Changeset.add_error(changeset,
                          :reactivation_date,
                          "Should be less than account's cancellation date.")
    end
  end
  defp validate_cancel_suspend_date(changeset, _changeset), do: changeset

  defp validate_expiry_suspend_date(%Account{} = account, changeset) do
    expiry_date =
      account.end_date
      |> Ecto.Date.to_iso8601()
      |> Date.from_iso8601!()

    {:ok, reactive_date} =
      changeset.changes.reactivation_date
      |> Timex.parse("{0M}/{D}/{YYYY}")

    if Date.compare(reactive_date, expiry_date) == :lt do
      update_account_status(account, changeset, :reactivate)
    else
      Changeset.add_error(changeset,
                          :reactivation_date,
                          "Should be less than account's expiry date.")
    end
  end
  defp validate_expiry_suspend_date(changeset, _changeset), do: changeset

  defp update_account_status(%Account{} = account, changeset, :reactivate) do
    account =
      account
      |> Account.changeset_reactivate_sap_api(changeset.changes)
      |> Repo.update()

    {changeset, account}
  end

  def valid_params?(:suspend_account, params) do
    fields = %{
      code: :string,
      effectivity_date: :string,
      expiry_date: :string,
      suspension_date: :string,
      reason: :string,
      remarks: :string,
      version: :string,
      created_by: :string,
      updated_by: :string
    }
    changeset =
      {%{}, fields}
      |> Changeset.cast(params, Map.keys(fields))
      |> Changeset.validate_required([:reason], message: "Enter reason")
      |> Changeset.validate_required([:effectivity_date], message: "Enter effectivity date")
      |> Changeset.validate_required([:expiry_date], message: "Enter expiry date")
      |> Changeset.validate_required([:suspension_date], message: "Enter suspension date")
      |> Changeset.validate_required([:version], message: "Enter version")
      |> Changeset.validate_required([:code], message: "Enter account code")
      |> Changeset.validate_inclusion(:reason, ["Test1", "Test2", "Test3"], message: "Reason is invalid")
      |> Changeset.validate_length(:remarks, max: 255, message: "Must not exceed 255 characters")
      |> validate_all_date_format(:suspend)
      |> transform_date(:suspend)
      |> validate_suspend_date(:suspend)
      |> check_remarks(:suspend)
      |> validate_account(:suspend)
      |> is_cancelled_account?()
  end

  defp validate_all_date_format(changeset, :suspend) do
    changeset
    |> check_if_has_key?(:effectivity_date)
    |> check_if_has_key?(:expiry_date)
    |> check_if_has_key?(:suspension_date)
  end

  defp check_if_has_key?(changeset, :suspension_date = key) do
    if Map.has_key?(changeset.changes, key) do
      changeset =
        changeset
        |> validate_date_format(changeset.changes.suspension_date, key)
    else
      changeset
    end
  end

  defp check_remarks(changeset, :suspend) do
    if Map.has_key?(changeset.changes, :remarks) do
      changeset
      |> Changeset.put_change(:suspend_remarks, changeset.changes.remarks)
    else
      changeset
      |> Changeset.put_change(:suspend_remarks, "")
    end
  end

  defp validate_suspend_date(changeset, :suspend) do
    if changeset.valid? do
      {:ok, date} =
        changeset.changes.suspension_date
        |> Timex.parse("{0M}/{D}/{YYYY}")
        if Date.compare(date, Date.utc_today()) == :gt do
          {:ok, date} =  Ecto.Date.cast(date)
          changeset
          |> Changeset.put_change(:suspend_date, date)
          |> Changeset.put_change(:suspend_reason, changeset.changes.reason)
        else
          Changeset.add_error(changeset,
                              :suspension_date,
                              "Should be future dated.")
        end
    else
      changeset
    end
  end

  defp validate_account(changeset, :suspend) do
    if changeset.valid? do
      changeset
      |> validate_account_code(:suspend)
      |> find_account_for_renewal(changeset)
      |> validate_version(changeset, :suspend)
      |> validate_start_date(changeset)
      |> validate_end_date()
      |> validate_status_account(changeset, :suspend)
    else
      changeset
    end
  end

  defp validate_account_code(changeset, :suspend) do
    Account
    |> join(:inner, [a], ag in AccountGroup, a.account_group_id == ag.id)
    |> where([a, ag], ag.code == ^changeset.changes.code)
    |> Repo.all()
  end

  defp validate_version(accounts, changeset, :suspend) when is_list(accounts) do
    version = changeset.changes.version
              |> find_account_version(accounts, changeset)
  end
  defp validate_version(changeset, _changeset, :suspend), do: changeset

  defp validate_version(accounts, changeset, :cancel) when is_list(accounts) do
    version = changeset.changes.version
              |> find_account_version(accounts, changeset)
  end
  defp validate_version(changeset, _changeset, :cancel), do: changeset

  defp find_account_version(version, accounts, changeset, :suspend) do
    acc = Enum.map(accounts, fn(account) ->
      account_ver = transform_account_version(account, :suspend)
      if "#{account_ver}" == version do
        account
      end
    end)
    |> Enum.uniq
    |> List.delete(nil)

    if is_nil(List.first(acc)) do
      Changeset.add_error(changeset, :version, "Account version not found.")
    else
      List.first(acc)
    end
  end

  defp transform_account_version(account, :suspend) do
    version = [account.major_version, account.minor_version, account.build_version]
              |> Enum.join(".")
  end

  defp validate_status_account(%Account{} = accounts, changeset, :suspend) do
    if accounts.status == "Active" do
      if is_nil(accounts.cancel_date) and
         is_nil(accounts.suspend_date) do
            accounts
            |> check_if_date_lapse(changeset, :suspend)

      else
        keys = [:suspend_date, :cancel_date]
               |> Enum.map(fn(key) ->
                 accounts
                 |> check_if_future_dated_suspend(changeset, key)
               end)

               |> check_errors_in_date(accounts)
               |> check_if_date_lapse(changeset, :suspend)
      end
    else
      Changeset.add_error(changeset,
                          :code,
                          "Account can't be suspended: status should be Active.")
    end
  end

  defp validate_status_account(changeset, _, :suspend), do: changeset

  defp check_if_date_lapse(%Account{} = account, changeset, :suspend) do
    exp_date =
      account.end_date
      |> Ecto.Date.to_iso8601()
      |> Date.from_iso8601!()

    {:ok, sus_date} =
      changeset.changes.suspension_date
      |> Timex.parse("{0M}/{D}/{YYYY}")

    if Date.compare(sus_date, exp_date) == :lt do
      update_account_status(account, changeset, :suspend)
    else
      Changeset.add_error(changeset,
                          :suspension_date,
                          "Should be less than account's expiry date.")
    end
  end

  defp check_if_date_lapse(changeset, _changeset, :suspend), do: changeset

  defp update_account_status(%Account{} = account, changeset, :suspend) do
    account =
      account
      |> Account.changeset_suspend_sap_api(changeset.changes)
      |> Repo.update()

    {changeset, account}
  end

  def valid_params?(:extend_account, params) do
    fields = %{
      code: :string,
      effectivity_date: :string,
      current_expiry_date: :string,
      new_expiry_date: :string,
      remarks: :string,
      version: :string,
      created_by: :string,
      updated_by: :string
    }
    changeset =
      {%{}, fields}
      |> Changeset.cast(params, Map.keys(fields))
      |> Changeset.validate_required([:effectivity_date], message: "Enter effectivity date")
      |> Changeset.validate_required([:current_expiry_date], message: "Enter current expiry date")
      |> Changeset.validate_required([:new_expiry_date], message: "Enter new expiry date")
      |> Changeset.validate_required([:version], message: "Enter version")
      |> Changeset.validate_required([:code], message: "Enter account code")
      |> Changeset.validate_length(:remarks, max: 255, message: "Must not exceed 255 characters")
      |> validate_all_date_format(:extend)
      |> transform_date(:extend)
      |> validate_new_expiry_date(:extend)
      |> check_remarks(:extend)
      |> validate_account(:extend)
      |> is_cancelled_account?()
  end

  defp validate_all_date_format(changeset, :extend) do
    changeset
    |> check_if_has_key?(:effectivity_date)
    |> check_if_has_key?(:current_expiry_date)
    |> check_if_has_key?(:new_expiry_date)
  end

  defp check_if_has_key?(changeset, :current_expiry_date = key) do
    if Map.has_key?(changeset.changes, key) do
      changeset =
        changeset
        |> validate_date_format(changeset.changes.current_expiry_date, key)
    else
      changeset
    end
  end

  defp check_if_has_key?(changeset, :new_expiry_date = key) do
    if Map.has_key?(changeset.changes, key) do
      changeset =
        changeset
        |> validate_date_format(changeset.changes.new_expiry_date, key)
    else
      changeset
    end
  end

  defp transform_date(changeset, :extend) do
   if changeset.valid? do
    changeset
    |> convert_date(changeset.changes.effectivity_date, :effectivity_date)
    |> convert_date(changeset.changes.current_expiry_date, :current_expiry_date)
    |> convert_date(changeset.changes.new_expiry_date, :new_expiry_date)
   else
      changeset
   end
  end

  defp transform_date(changeset, :suspend) do
   if changeset.valid? do
    changeset
    |> convert_date(changeset.changes.effectivity_date, :effectivity_date)
    |> convert_date(changeset.changes.expiry_date, :expiry_date)
    |> convert_date(changeset.changes.suspension_date, :suspension_date)
   else
      changeset
    end
  end

  defp transform_date(changeset, :cancel) do
    if changeset.valid? do
      changeset
      |> convert_date(changeset.changes.effectivity_date, :effectivity_date)
      |> convert_date(changeset.changes.expiry_date, :expiry_date)
      |> convert_date(changeset.changes.cancellation_date, :cancellation_date)
    else
      changeset
    end
  end

  defp transform_date(changeset, :reactivate) do
    if changeset.valid? do
      changeset
      |> convert_date(changeset.changes.effectivity_date, :effectivity_date)
      |> convert_date(changeset.changes.expiry_date, :expiry_date)
      |> convert_date(changeset.changes.reactivation_date, :reactivation_date)
    else
      changeset
    end
  end

 defp convert_date(changeset, date, key) do
    month = String.slice(date, 0..2)
    case month do
      "Jan" -> new_month = "01"
      "Feb" -> new_month = "02"
      "Mar" -> new_month = "03"
      "Apr" -> new_month = "04"
      "May" -> new_month = "05"
      "Jun" -> new_month = "06"
      "Jul" -> new_month = "07"
      "Aug" -> new_month = "08"
      "Sep" -> new_month = "09"
      "Oct" -> new_month = "10"
      "Nov" -> new_month = "11"
      "Dec" -> new_month = "12"
         _  -> new_month = :invalid
    end

    check_month(new_month, changeset, key, date)
  end

  defp check_month(new_month, changeset, key, date) do
   list = date
    |> String.split("-")
    |> List.replace_at(0, new_month)
    |> Enum.join("/")

    changeset
    |> Changeset.put_change(key, list)
  end

  defp check_remarks(changeset, :extend) do
    if Map.has_key?(changeset.changes, :remarks) do
      changeset
      |> Changeset.put_change(:extend_remarks, changeset.changes.remarks)
    else
      changeset
      |> Changeset.put_change(:extend_remarks, "")
    end
  end

  defp validate_new_expiry_date(changeset, :extend) do
    if changeset.valid? do
      {:ok, date} =
        changeset.changes.new_expiry_date
        |> Timex.parse("{0M}/{D}/{YYYY}")
        if Date.compare(date, Date.utc_today()) == :gt do
          {:ok, date} =  Ecto.Date.cast(date)
          changeset
          |> Changeset.put_change(:end_date, date)
        else
          Changeset.add_error(changeset,
                              :new_expiry_date,
                              "Should be future dated.")
        end
    else
      changeset
    end
  end

  defp validate_account(changeset, :extend) do
    if changeset.valid? do
      changeset
      |> validate_account_code(:extend)
      |> find_account_for_renewal(changeset)
      |> validate_version(changeset, :extend)
      |> validate_start_date(changeset)
      |> validate_end_date(:extend)
      |> validate_status_account(changeset, :extend)
    else
      changeset
    end
  end

  defp validate_end_date({changeset, account}, :extend) do
    end_date =
      account.end_date
      |> Ecto.Date.to_iso8601()
      |> Date.from_iso8601!()

    {:ok, exp_date} =
      changeset.changes.current_expiry_date
      |> Timex.parse("{0M}/{D}/{YYYY}")

    if Date.compare(end_date, exp_date) == :eq do
      if changeset.valid? do
          account
      else
        changeset
      end
    else
      Changeset.add_error(changeset,
                          :current_expiry_date,
                          "Not equal to account's expiry date")
    end
  end
  defp validate_end_date(changeset, :extend), do: changeset

  defp validate_account_code(changeset, :extend) do
    Account
    |> join(:inner, [a], ag in AccountGroup, a.account_group_id == ag.id)
    |> where([a, ag], ag.code == ^changeset.changes.code)
    |> Repo.all()
  end

  defp validate_version(accounts, changeset, :extend) when is_list(accounts) do
    version = changeset.changes.version
              |> find_account_version(accounts, changeset)
  end
  defp validate_version(changeset, _changeset, :extend), do: changeset

  defp find_account_version(version, accounts, changeset, :extend) do
    acc = Enum.map(accounts, fn(account) ->
      account_ver = transform_account_version(account, :extend)
      if "#{account_ver}" == version do
        account
      end
    end)
    |> Enum.uniq
    |> List.delete(nil)

    if is_nil(List.first(acc)) do
      Changeset.add_error(changeset, :version, "Account version not found.")
    else
      List.first(acc)
    end
  end

  defp transform_account_version(account, :extend) do
    version = [account.major_version, account.minor_version, account.build_version]
              |> Enum.join(".")
  end

  defp validate_status_account(%Account{} = accounts, changeset, :extend) do
    if accounts.status == "Active" do
      accounts
      |> check_if_date_lapse(changeset, :extend)
    else
      Changeset.add_error(changeset,
                          :code,
                          "Account can't be extended: status should be Active.")
    end
  end

  defp validate_status_account(changeset, _, :extend), do: changeset

  defp check_if_date_lapse(%Account{} = account, changeset, :extend) do
    exp_date =
      account.end_date
      |> Ecto.Date.to_iso8601()
      |> Date.from_iso8601!()

    {:ok, new_ex_date} =
      changeset.changes.new_expiry_date
      |> Timex.parse("{0M}/{D}/{YYYY}")

    if Date.compare(new_ex_date, exp_date) == :gt do
      update_account_status(account, changeset, :extend)
    else
      Changeset.add_error(changeset,
                          :new_expiry_date,
                          "Should be greater than account's expiry date.")
    end
  end

  defp check_if_date_lapse(changeset, _changeset, :extend), do: changeset

  defp update_account_status(%Account{} = account, changeset, :extend) do
    account =
      account
      |> Account.changeset_extend_sap_api(changeset.changes)
      |> Repo.update()

    {changeset, account}
  end

  def get_sap_account(code, name) do
    AccountGroup
    |> join(:inner, [ag], i in Industry, ag.industry_id == i.id)
    |> where([ag, i], ag.code == ^code or ag.name == ^name)
    |> select([ag, i], %{
      id: ag.id,
      name: ag.name,
      segment: ag.segment,
      industry_code: i.code,
      original_effective_date: ag.original_effective_date,
      type: ag.type,
      phone_no: ag.phone_no,
      email: ag.email
    })
    |> Repo.all()
    |> check_results()
  end

  # def get_sap_account(code, name) do
  #   Account
  #   |> join(:inner, [a], ag in AccountGroup, a.account_group_id == ag.id)
  #   |> join(:inner, [a, ag], i in Industry, ag.industry_id == i.id)
  #   |> where([a, ag], ag.code == ^code or ag.name == ^name)
  #   |> where([a, ag], a.status == "Active")
  #   |> select([a, ag, i], %{
  #     id: ag.id,
  #     name: ag.name,
  #     segment: ag.segment,
  #     industry_code: i.code,
  #     effectivity_date: a.start_date,
  #     expiry_date: a.end_date,
  #     original_effective_date: ag.original_effective_date,
  #     type: ag.type,
  #     phone_no: ag.phone_no,
  #     email: ag.email
  #   })
  #   |> Repo.all()
  #   |> check_results()
  # end

  defp check_results([account_group]) do
    {
      :ok,
      account_group
      |> load_account()
      |> load_addresses()
      |> load_personnels()
      |> load_contacts()
      |> load_financial()
    }
  end
  defp check_results([]), do: {:no_record_found}
  defp check_results(accounts), do: {:multiple_results}

  defp load_account(nil), do: nil
  defp load_account(account_group) do
    account =
      Account
      |> where([a], a.account_group_id == ^account_group.id)
      |> limit(1)
      |> select([a], %{
        effectivity_date: a.start_date,
        expiry_date: a.end_date,
        id: a.id
      })
      |> order_by([a], desc: a.inserted_at)
      |> Repo.one()
    if is_nil(account) do
      nil
    else
      account_group
      |> Map.put(:effectivity_date, account.effectivity_date)
      |> Map.put(:expiry_date, account.expiry_date)
    end
  end

  defp load_addresses(nil), do: nil
  defp load_addresses(account) do
    addresses =
      AccountGroupAddress
      |> where([aga], aga.account_group_id == ^account.id)
      |> Repo.all()
    Map.put(account, :addresses, addresses)
  end

  defp load_personnels(nil), do: nil
  defp load_personnels(account) do
    personnels =
      AccountGroupPersonnel
      |> where([agp], agp.account_group_id == ^account.id)
      |> Repo.all()
    Map.put(account, :personnels, personnels)
  end

  defp load_financial(nil), do: nil
  defp load_financial(account) do
    financial =
      PaymentAccount
      |> where([pa], pa.account_group_id == ^account.id)
      |> limit(1)
      |> Repo.one()
    Map.put(account, :financial, financial)
  end

  defp load_contacts(nil), do: nil
  defp load_contacts(account) do
    contacts =
      Contact
      |> join(:inner, [c], agc in AccountGroupContact, agc.contact_id == c.id)
      |> where([c, agc], agc.account_group_id == ^account.id)
      |> Repo.all()
      |> Repo.preload([
        :phones,
        :fax
      ])
    Map.put(account, :contacts, contacts)
  end

end

