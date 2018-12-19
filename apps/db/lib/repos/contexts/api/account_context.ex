defmodule Innerpeace.Db.Base.Api.AccountContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias Ecto.Changeset
  alias Ecto.UUID
  import Date
  import Innerpeace.Db.Base.{
    AccountContext,
    CoverageContext
  }
  alias Innerpeace.Db.Base.Api.UtilityContext
  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.Account,
    Db.Schemas.AccountComment,
    Db.Schemas.AccountGroup,
    Db.Schemas.AccountGroupCoverageFund,
    Db.Schemas.AccountGroupApproval,
    Db.Schemas.AccountGroupAddress,
    Db.Schemas.AccountGroupApproval,
    Db.Schemas.AccountGroupContact,
    Db.Schemas.AccountLog,
    Db.Schemas.AccountProduct,
    Db.Schemas.AccountProductBenefit,
    Db.Schemas.FulfillmentCard,
    Db.Schemas.AccountGroupFulfillment,
    Db.Schemas.Bank,
    Db.Schemas.BankBranch,
    Db.Schemas.Contact,
    Db.Schemas.Fax,
    Db.Schemas.PaymentAccount,
    Db.Schemas.Phone,
    Db.Schemas.Product,
    Db.Schemas.ProductBenefit,
    Db.Schemas.Industry,
    Db.Schemas.AccountGroupCluster,
    Db.Schemas.Cluster,
    Db.Schemas.User,
    Db.Schemas.Member,
    Db.Schemas.AccountHierarchyOfEligibleDependent
  }
  alias Innerpeace.PayorLink.Web.AccountView

  # API
  def search_accounts(params) do
    AccountGroup
    |> where([ag],
             fragment("lower(?)", ag.code) ==
               fragment("lower(?)", ^params["account"])
    )
    #  |> order_by([ag], asc: ag.inserted_at)
    |> Repo.all
    |> Repo.preload([
      :payment_account,
      :industry,
      :account_hierarchy_of_eligible_dependents,
      :account_group_address,
      account: :account_products,
      account_group_contacts: [
        contact: [
          :phones
        ]
      ]
    ])
  end

  def get_all_accounts do
    AccountGroup
    |> Repo.all
    |> Repo.preload([
      :payment_account,
      :industry,
      :account_hierarchy_of_eligible_dependents,
      :account_group_address,
      account: :account_products,
      account_group_contacts: [
        contact: [
          :phones
        ]
      ]
    ])
  end

  def validate_insert(user, params) do
    with {:ok, changeset} <- validate_general(params),
         {:ok, changeset2} <- validate_address(changeset),
         {:ok, changeset3} <- validate_address2(changeset),
         {:ok, account_group} <- insert_account_group(changeset),
         {:ok, account} <- insert_account(params = Map.merge(params, %{
           "account_group_id" => account_group.id,
           "updated_by" => user.id
         })),
         {:ok, account_group_address} <- insert_address2(params,
                                                         account_group.id),
         contact_array <- insert_contact(params, params["contact"]),
         account_contact_array <- insert_account_contact(account_group.id,
                                                         contact_array),
         coverage_fund <- insert_coverage_fund(params["coverage_fund"], account_group),
         hierarchy_of_eligible_dependent <-
           insert_hierarchy_of_eligible_dependent(
             params["hierarchy_of_eligible_dependent"],
             account_group.id),
         approvers <- insert_approvers(params["approvers"], account_group.id),
         products <- insert_products(changeset, account.id),
         fulfillments <- insert_fulfillments(params["fulfillments"] || [],
                                             account_group.id),
         account_group = %AccountGroup{} <-
           get_account_group_list(account_group.id),
         account_product <- list_all_account_products(account.id),
         approver <- list_all_approver(account_group.id)
    do
      {:ok, account_group, account_product, approver}
    else
      {:error, changeset} ->
        {:error, changeset}
      _ ->
        {:not_found}
    end
  end

  defp validate_general(params) do
    # Changes
    if is_nil(params["expiry_date"]) do
      expiry_date = params["expiry_date"]
    else
      expiry_date = String.replace(params["expiry_date"], "‑", "-")
      params =
        params
        |> Map.put("expiry_date", expiry_date)
    end

    # Changes
    if is_nil(params["effective_date"]) do
      effective_date = params["effective_date"]
    else
      effective_date = String.replace(params["effective_date"], "‑", "-")
      params =
        params
        |> Map.put("effective_date", effective_date)
    end

    if is_nil(params["original_effective_date"]) do
      original_effective_date = nil
    else
      original_effective_date = String.replace(params["original_effective_date"], "‑", "-")
      params =
        params
        |> Map.put("original_effective_date", original_effective_date)
    end

    # Changes
    if is_nil(params["industry_code"]) do
      industry_code = params["industry_code"]
    else
      industry_code = String.replace(params["industry_code"], "‑", "-")
      params =
        params
        |> Map.put("industry_code", industry_code)
    end

    data = %{}
    general_types = %{
      policy_no: :string,
      code: :string,
      name: :string,
      type: :string,
      segment: :string,
      phone_no: :string,
      email: :string,
      remarks: :string,
      effective_date: Ecto.Date,
      original_effective_date: Ecto.Date,
      expiry_date: Ecto.Date,
      industry_code: :string,
      is_billing_same_with_company: :boolean,
      company_address: :map,
      billing_address: :map,
      contact: {:array, :map},
      coverage_fund: {:array, :map},
      approvers: {:array, :map},
      products: :map,
      hierarchy_of_eligible_dependent: {:array, :map},
      fulfillments: {:array, :map}
    }
    changeset =
      {data, general_types}
      |> Changeset.cast(params, Map.keys(general_types))
      |> Changeset.validate_required([
        :name,
        :type,
        :segment,
        :industry_code,
        :original_effective_date,
        :effective_date,
        :expiry_date,
        :is_billing_same_with_company,
        :company_address,
        # :contact,
      ])
      |> Changeset.validate_number(:phone_no, message: "Must be a number.")
      |> Changeset.validate_length(:phone_no, is: 11,
                                   message: "should be 11 characters"
      )
      |> Changeset.validate_format(
        :email,
        ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/
      )
      |> validate_inclusion(:type, ["Headquarters", "Subsidiary", "Branch"])
      |> validate_inclusion(:segment, ["Corporate", "Individual",
                                       "Family", "Group"])
      |> validate_address_fields()
      |> validate_industry_code()
      |> validate_contact()
      |> validate_approvers()
      |> validate_products()
      |> validate_hierarchy()
      |> validate_account_code()
      |> validate_fulfillment()
      # |> validate_effectivity_date()
      |> validate_coverage_fund()

    new_changeset =
      changeset.changes
      |> Map.put_new(:phone_no, "")

    changeset2 =
      changeset.changes
      |> Map.put_new(:expiry_date, Ecto.Date.cast!("0002-02-02"))
      |> Map.put_new(:effective_date, Ecto.Date.cast!("0001-01-01"))

    changeset = validate_all_number_fields(new_changeset.phone_no,
                                           :phone_no, changeset)

    if is_nil(params["effective_date"]) do
      changeset
    else
      changeset =
        effective_date
        |> validate_date_format(:effective_date, changeset)
    end

    if is_nil(params["original_effective_date"]) do
      changeset
    else
      changeset =
        original_effective_date
        |> validate_date_format(:original_effective_date, changeset)
    end

    if is_nil(params["expiry_date"]) do
      changeset
    else
      changeset =
        expiry_date
        |> validate_date_format(:expiry_date, changeset)
    end

    changeset = validate_account_date(changeset2, changeset)

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  def validate_insert_existing(user, params)do
    with {:ok, changeset} <- validate_general_existing(params),
         {:ok, changeset2} <- validate_address(changeset),
         {:ok, changeset3} <- validate_address2(changeset),
         {:ok, account_group} <- insert_account_group(changeset),
         {:ok, account} <- insert_account_active(params = Map.merge(params, %{
           "account_group_id" => account_group.id,
           "updated_by" => user.id
         })),
         {:ok, account_group_address} <- insert_address2(params,
                                                         account_group.id),
         contact_array <- insert_contact(params, params["contact"]),
         account_contact_array <- insert_account_contact(account_group.id,
                                                         contact_array),
         hierarchy_of_eligible_dependent <-
           insert_hierarchy_of_eligible_dependent(
             params["hierarchy_of_eligible_dependent"],
             account_group.id),
         approvers <- insert_approvers(params["approvers"], account_group.id),
         products <- insert_products(changeset, account.id),
         fulfillments <- insert_fulfillments(params["fulfillments"] || [],
                                             account_group.id),
         account_group = %AccountGroup{} <-
           get_account_group_list(account_group.id),
         account_product <- list_all_account_products(account.id),
         approver <- list_all_approver(account_group.id)
    do
      {:ok, account_group, account_product, approver}
    else
      {:error, changeset} ->
        {:error, changeset}
      _ ->
        {:not_found}
    end
  end

  defp validate_general_existing(params) do
    # Changes
    if is_nil(params["expiry_date"]) do
      expiry_date = params["expiry_date"]
    else
      expiry_date = String.replace(params["expiry_date"], "‑", "-")
      params =
        params
        |> Map.put("expiry_date", expiry_date)
    end

    # Changes
    if is_nil(params["effective_date"]) do
      effective_date = params["effective_date"]
    else
      effective_date = String.replace(params["effective_date"], "‑", "-")
      params =
        params
        |> Map.put("effective_date", effective_date)
    end

    # Changes
    if is_nil(params["industry_code"]) do
      industry_code = params["industry_code"]
    else
      industry_code = String.replace(params["industry_code"], "‑", "-")
      params =
        params
        |> Map.put("industry_code", industry_code)
    end

    data = %{}
    general_types = %{
      policy_no: :string,
      code: :string,
      name: :string,
      type: :string,
      segment: :string,
      phone_no: :string,
      email: :string,
      remarks: :string,
      effective_date: Ecto.Date,
      expiry_date: Ecto.Date,
      industry_code: :string,
      is_billing_same_with_company: :boolean,
      company_address: :map,
      billing_address: :map,
      contact: {:array, :map},
      approvers: {:array, :map},
      products: :map,
      hierarchy_of_eligible_dependent: {:array, :map},
      fulfillments: {:array, :map}
    }
    changeset =
      {data, general_types}
      |> Changeset.cast(params, Map.keys(general_types))
      |> Changeset.validate_required([
        :name,
        :type,
        :segment,
        :industry_code,
        :effective_date,
        :expiry_date,
        :is_billing_same_with_company,
        :company_address,
        :contact,
      ])
      |> Changeset.validate_number(:phone_no, message: "Must be a number.")
      |> Changeset.validate_length(:phone_no, is: 11,
                                   message: "should be 11 characters"
      )
      |> Changeset.validate_format(
        :email,
        ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/
      )
      |> validate_inclusion(:type, ["Headquarters", "Subsidiary", "Branch"])
      |> validate_inclusion(:segment, ["Corporate", "Individual",
                                       "Family", "Group"])
      |> validate_address_fields()
      |> validate_industry_code()
      |> validate_contact()
      |> validate_approvers()
      |> validate_products()
      |> validate_hierarchy()
      |> validate_account_code()
      |> validate_fulfillment()
    new_changeset =
      changeset.changes
      |> Map.put_new(:phone_no, "")

    changeset2 =
      changeset.changes
      |> Map.put_new(:expiry_date, Ecto.Date.cast!("0002-02-02"))
      |> Map.put_new(:effective_date, Ecto.Date.cast!("0001-01-01"))

    changeset = validate_all_number_fields(new_changeset.phone_no,
                                           :phone_no, changeset)

    if is_nil(params["effective_date"]) do
      changeset
    else
      changeset =
        effective_date
        |> validate_date_format(:effective_date, changeset)
    end

    if is_nil(params["expiry_date"]) do
      changeset
    else
      changeset =
        expiry_date
        |> validate_date_format(:expiry_date, changeset)
    end

    changeset = validate_account_date(changeset2, changeset)

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp validate_account_code(changeset) do
    with true <- Map.has_key?(changeset.changes, :segment) do
      if Map.has_key?(changeset.changes, :code) do
        Changeset.validate_exclusion(changeset, :code,
                                     get_all_account_codes(),
                                     message: "Account Code already exists")
      else
        Changeset.put_change(changeset, :code,
                             account_code_checker(
                               String.first(changeset.changes.segment)
                             ))
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_date_format(changeset_field, field, changeset) do
    with true <- validate_date(changeset_field, field)
      do
        changeset
      else
        {:invalid_date_format, field} ->
        add_error(changeset, field, "Date must be on (YYYY-MM-DD) format.")
      end
  end

  defp validate_date(dates, field_name) do
      valid_format = validate_dates(dates)
      if valid_format do
        true
      else
        {:invalid_date_format, field_name}
      end
  end

  defp validate_dates(string) do
    Regex.match?(~r/[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$/,
                                              string)
  end

  defp validate_effectivity_date(changeset) do
    with true <- Map.has_key?(changeset.changes, :effective_date) do
      if Ecto.Date.compare(
        Ecto.Date.utc(), changeset.changes.effective_date
      ) != :lt do
        add_error(changeset, :effective_date,
                  "Effective Date must be future dated")
      else
        changeset
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_account_date(changeset2, changeset) do
    if is_nil(changeset2.expiry_date) or is_nil(changeset2.effective_date) do
      changeset
    else
      date_compare =  Ecto.Date.compare(changeset2.expiry_date,
                                        changeset2.effective_date)
      if date_compare == :lt or date_compare == :eq do
        add_error(changeset, :expiry_date,
                  "Expiry Date must be greater than Effective Date")
      else
        changeset
      end
    end
  end

  defp validate_financial(changeset) do
    if is_nil(changeset.changes[:financial]) do
      changeset
    else
      if Map.has_key?(changeset.changes.financial, "payment_mode") do
        case changeset.changes.financial["payment_mode"] do
          "Electronic Debit" ->
            validate_financial_electronic(changeset)
          "Check" ->
            validate_financial_check(changeset)
          _ ->
            add_error(changeset, :financial, "Invalid mode of payment")
        end
      else
        add_error(changeset, :financial, "Invalid financial parameters")
      end
    end
  end

  defp validate_financial_electronic(changeset) do
    # Changes
    if is_nil(changeset.changes.financial["vat_status"]) do
      changeset_financial = changeset.changes.financial
    else
      vat_status =
        if changeset.changes.financial["vat_status"] == "" do
          ""
        else
          String.replace(changeset.changes.financial["vat_status"],
                                    "‑", "-")
        end
      changeset_financial =
        changeset.changes.financial
        |> Map.put("vat_status", vat_status)
    end

    data = %{}
    financial_types = %{
      funding_arrangement: :string,
      tin: :string,
      # principal_schedule_payment: :string,
      # dependent_schedule_payment: :string,
      vat_status: :string,
      bank_name: :string,
      payment_mode: :string,
      previous_carrier: :string,
      attached_point: :string,
      # revolving_fund: :string,
      # replenish_threshold: :string,
      authority_to_debit: :boolean,
      bank_account_number: :string,
      bank_branch: :string,
      special_approval: :map
    }
    financial_changeset =
      {data, financial_types}
      |> Changeset.cast(changeset_financial, Map.keys(financial_types))
      |> Changeset.validate_required([
        # :funding_arrangement,
        # :tin,
        # :vat_status
        # :principal_schedule_payment,
        # :dependent_schedule_payment
        # :bank_name,
        # :bank_account_number,
        # :authority_to_debit,
        # :special_approval
      ])
      # |> validate_inclusion(:dependent_schedule_payment,
                            # ["ANNUAL", "SEMI ANNUAL", "QUARTERLY", "MONTHLY"]
      # )
      |> validate_inclusion(:vat_status,
                            ["20% VAT-able", "Fully VAT-able", "Others",
                             "VAT Exempt", "VAT-able", "Zero-Rated"]
      )

    # Changes
    if Map.has_key?(changeset.changes.financial, "special_approval") do
      financial_changeset =
        financial_changeset
        |> validate_approval_electronic()
        # |> validate_funding_arrangement()
        # |> validate_tin()
    else
      financial_changeset =
        financial_changeset
        # |> validate_funding_arrangement()
        # |> validate_tin()
    end

    new_changeset =
      financial_changeset.changes
      # |> Map.put_new(:replenish_threshold, "")
      |> Map.put_new(:bank_account_number, "")

    # financial_changeset =
    #   validate_all_number_fields(
    #     new_changeset.replenish_threshold,
    #     :replenish_threshold,
    #     financial_changeset
    #   )

    financial_changeset =
      validate_all_number_fields(
        new_changeset.bank_account_number,
        :bank_account_number,
        financial_changeset
      )

    if financial_changeset.valid? do
      changeset
    else
      add_error(Changeset.merge(changeset, financial_changeset),
                                :financial, "Invalid financial parameters")
    end
  end

  # defp validate_funding_arrangement(changeset) do
  #   if is_nil(changeset.changes[:funding_arrangement]) do
  #     changeset
  #   else
  #     if changeset.changes.funding_arrangement == "ASO" do
  #     changeset =
  #       changeset
  #       |> Changeset.validate_required([:replenish_threshold])
  #     else
  #       changeset
  #     end
  #   end
  # end

  defp validate_tin(changeset) do
    if is_nil(changeset.changes[:tin]) do
      changeset
    else
      payment_account =
      PaymentAccount
      |> Repo.get_by(account_tin: changeset.changes.tin)

      if is_nil(payment_account) do
        changeset
      else
        add_error(changeset, :financial, "TIN number must be unique")
      end
    end
  end

  defp validate_financial_check(changeset) do
    data = %{}
    financial_types = %{
      funding_arrangement: :string,
      tin: :string,
      # principal_schedule_payment: :string,
      # dependent_schedule_payment: :string,
      vat_status: :string,
      payment_mode: :string,
      previous_carrier: :string,
      attached_point: :string,
      # revolving_fund: :string,
      # replenish_threshold: :string,
      payee_name: :string,
      special_approval: :map
    }
    financial_changeset =
      {data, financial_types}
      |> Changeset.cast(changeset.changes.financial, Map.keys(financial_types))
      |> Changeset.validate_required([
        :funding_arrangement,
        :tin,
        :vat_status,
        # :principal_schedule_payment,
        # :dependent_schedule_payment,
        :payee_name,
        # :replenish_threshold
        # :special_approval
      ])
      # |> validate_inclusion(:dependent_schedule_payment,
                            # ["ANNUAL", "SEMI ANNUAL", "QUARTERLY", "MONTHLY"]
      # )
      # |> validate_inclusion(:principal_schedule_payment,
                            # ["ANNUAL", "SEMI ANNUAL", "QUARTERLY", "MONTHLY"]
      # )
      |> validate_inclusion(:vat_status,
                            ["20% VAT-able", "Fully VAT-able", "Others",
                             "VAT Exempt", "VAT-able", "Zero-Rated"]
      )
      |> validate_inclusion(:funding_arrangement, ["ASO", "Full Risk"])

      # Changes
      if Map.has_key?(changeset.changes.financial, "special_approval") do
        financial_changeset =
          financial_changeset
          |> validate_approval_check()
          # |> validate_tin()
      else
        financial_changeset =
          financial_changeset
          # |> validate_tin()
      end

    # new_changeset =
    #   financial_changeset.changes
    #   |> Map.put_new(:replenish_threshold, "")

    # financial_changeset =
    #   validate_all_number_fields(
    #     new_changeset.replenish_threshold,
    #     :replenish_threshold,
    #     financial_changeset
    #   )

    # if financial_changeset.valid? do
      changeset
    # else
      # add_error(Changeset.merge(changeset, financial_changeset),
                                # :financial, "Invalid financial parameters")
    # end
  end

  defp validate_approval_check(changeset) do
    data = %{}
    approval_types = %{
      is_funding_source: :boolean,
      payee_name: :string
    }

    approval_changeset =
      {data, approval_types}
      |> Changeset.cast(changeset.changes.special_approval,
                        Map.keys(approval_types))
      |> Changeset.validate_required([
        :is_funding_source
      ])
      |> validate_check_special_approval()

    if approval_changeset.valid? do
      changeset
    else
      add_error(Changeset.merge(changeset, approval_changeset),
                                :financial, "Invalid financial parameters")
    end
  end

  defp validate_check_special_approval(changeset) do
    with true <- Map.has_key?(changeset.changes, :is_funding_source) do
      if changeset.changes.is_funding_source do
        changeset
      else
        Changeset.validate_required(changeset, [
          :payee_name
        ])
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_approval_electronic(changeset) do
    data = %{}
    approval_types = %{
      is_funding_source: :boolean,
      bank_name: :string,
      bank_account_number: :string,
      authority_to_debit: :boolean,
      bank_branch: :string
    }

    approval_changeset =
      {data, approval_types}
      |> Changeset.cast(changeset.changes.special_approval,
                        Map.keys(approval_types))
      |> Changeset.validate_required([
        :is_funding_source
      ])
      # |> validate_electronic_special_approval()
    new_changeset =
        approval_changeset.changes
        |> Map.put_new(:bank_account_number, "")

    approval_changeset =
      validate_all_number_fields(
        new_changeset.bank_account_number,
        :bank_account_number,
        approval_changeset
      )

    if approval_changeset.valid? do
      changeset
    else
      add_error(Changeset.merge(changeset, approval_changeset),
                                :financial, "Invalid financial parameters")
    end
  end

  defp validate_electronic_special_approval(changeset) do
    with true <- Map.has_key?(changeset.changes, :is_funding_source) do
      if changeset.changes.is_funding_source do
       changeset
      else
        Changeset.validate_required(changeset, [
          :bank_name,
          :bank_account_number,
          :authority_to_debit
        ])
      end
    else
      _ ->
        changeset
    end
  end

  defp validate_fulfillment(changeset) do
    if is_nil(changeset.changes[:fulfillments]) do
      changeset
    else
      fulfillments = Changeset.get_field(changeset, :fulfillments)
      valid_fulfillment = for fulfillment <- fulfillments do
        fulfillment_field(fulfillment)
      end

      with true <- Enum.all?(valid_fulfillment, &(&1))
      do
        changeset
      else
        _ ->
          add_error(changeset, :fulfillments, "Invalid fulfillment parameters")
      end
    end
  end

  defp fulfillment_field(params) do
    data = %{}
    fulfillment_types = %{
      card: :string,
      type: :string,
      product_code_name: :string,
      image_url: :string,
      transmittal_listing: :string,
      packaging_style: :string
    }
    changeset =
      {data, fulfillment_types}
      |> Changeset.cast(params, Map.keys(fulfillment_types))
      |> Changeset.validate_required([
        :card,
        :product_code_name,
        :transmittal_listing,
        :packaging_style
      ])
      |> validate_inclusion(:card, ["EMV", "Digital", "Regular"])
      |> validate_fulfillment_required_fields()
      # |> validate_fulfillment_product_code_name()

    changeset.valid?
  end

  defp validate_fulfillment_product_code_name(changeset) do
    if is_nil(changeset.changes[:product_code_name]) do
      changeset
    else
      fulfillment_product_code_name =
        get_fulfillment_by_code(changeset.changes.product_code_name)
      if is_nil(fulfillment_product_code_name) do
        changeset
      else
        add_error(changeset, :fulfillments,
                  "Plan Code/Name is already used.")
      end
    end
  end

  defp validate_fulfillment_required_fields(changeset) do
    if is_nil(changeset.changes[:card]) do
      changeset
    else
      if changeset.changes.card == "EMV" do
        changeset
      else
        changeset =
          changeset
          |> Changeset.validate_required([
             :type
          ])
          |> validate_inclusion(:type, ["Premium", "Platinum"])
      end
    end
  end

  defp validate_contact(changeset) do
    if is_nil(changeset.changes[:contact]) do
      changeset
    else
      if Changeset.get_field(changeset, :contact) == [] do
        changeset
      else

        contacts = Changeset.get_field(changeset, :contact)
        valid_contact = for contact <- contacts, do: contact_field(contact)
        with true <- Enum.all?(valid_contact, &(&1))
             # true <- validate_contact_list(contacts)
        do
          changeset
        else
          {:at_least_one} ->
            add_error(changeset, :contact,
                      "At least one Contact Person and one Corp Signatory and one Account Officer is required")
          _ ->
            add_error(changeset, :contact, "Invalid contact parameters")
        end

      end

    end
  end

  defp validate_contact_list(contacts) do
    corp = for %{"type" => "Corp Signatory"} = contact <- contacts do
      contact
    end
    person = for %{"type" => "Contact Person"} = contact <- contacts do
      contact
    end
    officer = for %{"type" => "Account Officer"} = contact <- contacts do
      contact
    end
    if Enum.count(corp) > 0 and Enum.count(person) > 0 and Enum.count(officer) > 0 do
      true
    else
      {:at_least_one}
    end
  end

  defp validate_address_fields(changeset) do
    checker = get_field(changeset, :is_billing_same_with_company)
    if checker do
      changeset
    else
      if is_nil(get_field(changeset, :billing_address)) do
        add_error(changeset, :billing_address, "Invalid address parameters")
      else
        changeset
      end
    end
  end

  defp validate_address(changeset) do
    if changeset.changes.is_billing_same_with_company do
      address_field(changeset.changes.company_address)
    else
      address_field(changeset.changes.company_address)
    end
  end

  defp validate_address2(changeset) do
    if changeset.changes.is_billing_same_with_company do
      address_field(changeset.changes.company_address)
    else
      {:ok, changeset}
      #address_field(changeset.changes.billing_address)
    end
  end

  defp address_field(params) do
    data = %{}
    address_types = %{
      line_1: :string,
      line_2: :string,
      city: :string,
      province: :string,
      country: :string,
      region: :string,
      postal_code: :string
    }
    changeset =
      {data, address_types}
      |> Changeset.cast(params, Map.keys(address_types))
      |> Changeset.validate_required([
        :line_1,
        :line_2,
        :city,
        :province,
        :country,
        :region,
        :postal_code
      ])

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp contact_field(params) do
    # Changes
    if is_nil(params["ctc_date_issued"]) do
      ctc_date = params["ctc_date_issued"]
    else
      ctc_date = String.replace(params["ctc_date_issued"], "‑", "-")
      params =
        params
        |> Map.put("ctc_date_issued", ctc_date)
    end

    # Changes
    if is_nil(params["passport_date_issued"]) do
      passport_date = params["passport_date_issued"]
    else
      passport_date = String.replace(params["passport_date_issued"], "‑", "-")
      params =
        params
        |> Map.put("passport_date_issued", passport_date)
    end

    data = %{}
    contact_types = %{
      full_name: :string,
      designation: :string,
      type: :string,
      email: :string,
      ctc: :string,
      ctc_date_issued: Ecto.Date,
      ctc_place_issued: :string,
      passport_no: :string,
      passport_date_issued: Ecto.Date,
      passport_place_issued: :string,
      department: :string,
      mobile: {:array, :string},
      telephone: {:array, :string},
      fax: {:array, :string}
    }

    if params["type"] == "Account Officer" do
      changeset =
        {data, contact_types}
        |> Changeset.cast(params, Map.keys(contact_types))
        |> Changeset.validate_required([
          :full_name,
          :type
        ])
        |> Changeset.validate_format(
          :email,
          ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/
        )
        |> validate_telephones()
        |> validate_fax()
        |> validate_mobiles()
    else
      changeset =
      {data, contact_types}
      |> Changeset.cast(params, Map.keys(contact_types))
      |> Changeset.validate_required([
        :full_name,
        :type,
        :email,
        :mobile
      ])
      |> Changeset.validate_format(
        :email,
        ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/
      )
      |> validate_telephones()
      |> validate_fax()
      |> validate_mobiles()
    end
    new_changeset =
      changeset.changes
      |> Map.put_new(:passport_no, "")
      |> Map.put_new(:ctc, "")

    changeset = validate_all_number_fields(new_changeset.passport_no,
                                           :passport_no, changeset)
    changeset = validate_all_number_fields(new_changeset.ctc, :ctc, changeset)

    changeset.valid?
  end

   defp validate_telephones(changeset) do
    if Map.has_key?(changeset.changes, :telephone) do
      with true <- Enum.all?(changeset.changes.telephone,
                             &(String.length(&1) <= 11)),
           true <- Enum.all?(changeset.changes.telephone,
                             &(String.length(&1) >= 7)),
           true <- Enum.all?(validate_number_field(
             changeset.changes.telephone)),
           true <- Enum.all?(validate_number_field(
             changeset.changes.telephone))
      do
        changeset
      else
        _ ->
        add_error(changeset, :telephone, "Invalid params")
      end
    else
      changeset
    end
  end

  defp validate_mobiles(changeset) do
    if is_nil(changeset.changes[:mobile]) do
      changeset
    else
      with false <- Enum.empty?(changeset.changes.mobile),
           true <- Enum.all?(changeset.changes.mobile,
                             &(String.length(&1) >= 11)),
           true <- Enum.all?(changeset.changes.mobile,
                             &(String.length(&1) <= 13)),
           true <- Enum.all?(validate_number_field(changeset.changes.mobile)),
           true <- Enum.all?(validate_number_field(changeset.changes.mobile))
      do
        changeset
      else
        true ->
          add_error(changeset, :mobile,
                    "At least one mobile number is required")
        _ ->
          add_error(changeset, :mobile, "Invalid params")
      end
    end
  end

  defp validate_fax(changeset) do
    if Map.has_key?(changeset.changes, :fax) do
      with true <- Enum.all?(changeset.changes.fax, &(String.length(&1) <= 11)),
           true <- Enum.all?(changeset.changes.fax, &(String.length(&1) >= 7)),
         true <- Enum.all?(validate_number_field(changeset.changes.fax)),
         true <- Enum.all?(validate_number_field(changeset.changes.fax))
      do
        changeset
      else
        _ ->
        add_error(changeset, :fax, "Invalid params")
      end
    else
      changeset
    end
  end

  defp validate_approvers(changeset) do
    approver_array = Changeset.get_field(changeset, :approvers)
    if is_nil(approver_array) do
      changeset
    else
      checker = for approver <- approver_array, do: valid_approver?(approver)
      if Enum.all?(checker, &(&1)) do
        changeset
      else
        add_error(changeset, :approvers, "Invalid approvers parameters")
      end
    end
  end

  defp validate_products(changeset) do
    if is_nil(changeset.changes[:products]) do
      changeset
    else
      products = Changeset.get_field(changeset, :products)
      valid_product = product_field(products)
      with true <- valid_product,
           true <- validate_product_list(products)
      do
        changeset
      else
        {:at_least_one} ->
          add_error(changeset, :products,
                    "At least one product code is required")
        _ ->
          add_error(changeset, :products, "Invalid plan parameters")
      end
    end
  end

  defp validate_product_list(products) do
    if Enum.count(products["code"]) > 0 do
      true
    else
      {:at_least_one}
    end
  end

  defp product_field(params) do
    data = %{}
    product_types = %{
      code: {:array, :string}
    }
    changeset =
      {data, product_types}
      |> Changeset.cast(params, Map.keys(product_types))
      |> Changeset.validate_required([
        :code,
      ])
      |> validate_product_code()
    changeset.valid?
  end

  defp validate_product_code(changeset) do
    if is_nil(changeset.changes[:code]) do
      changeset
    else
      product_codes = Enum.map(changeset.changes.code,
                               &(get_product_by_code(&1)))
      if Enum.member?(product_codes, nil) do
        add_error(changeset, :code, "Invalid product code")
      else
        Map.put(changeset, :changes,
                Map.put(changeset.changes, :product_ids, product_codes)
        )
      end
    end
  end

  defp validate_hierarchy(changeset) do
    if is_nil(changeset.changes[:hierarchy_of_eligible_dependent]) do
      changeset
    else
      hierarchies = Changeset.get_field(changeset,
                                        :hierarchy_of_eligible_dependent
      )
      valid_hierarchy = for hierarchy <- hierarchies do
        hierarchy_field(hierarchy)
      end

      with true <- Enum.all?(valid_hierarchy, &(&1)),
           true <- validate_hierarchy_type(hierarchies)
      do
        changeset
      else
        {:married_hierarchy_ranking} ->
          add_error(changeset, :hierarchy, "Invalid Hierarchy Rank in Married Employee. Rank must be in consecutive order.")
        {:married_hierarchy_rank} ->
          add_error(changeset, :hierarchy, "Invalid Hierarchy Rank in Married Employee")
        {:married_hierarchy_dependent} ->
          add_error(changeset, :hierarchy, "Invalid Hierarchy Dependent in Married Employee. Choose other dependent.")
        {:single_parent_hierarchy_ranking} ->
          add_error(changeset, :hierarchy, "Invalid Hierarchy Rank in Single Parent Employee. Rank must be in consecutive order.")
        {:single_parent_hierarchy_rank} ->
          add_error(changeset, :hierarchy, "Invalid Hierarchy Rank in Single Parent Employee")
        {:single_parent_hierarchy_dependent} ->
          add_error(changeset, :hierarchy, "Invalid Hierarchy Dependent in Single Parent Employee. Choose other dependent.")
        {:single_hierarchy_ranking} ->
          add_error(changeset, :hierarchy, "Invalid Hierarchy Rank in Single Employee. Rank must be in consecutive order.")
        {:single_hierarchy_rank} ->
          add_error(changeset, :hierarchy, "Invalid Hierarchy Rank in Single Employee")
        {:single_hierarchy_dependent} ->
          add_error(changeset, :hierarchy, "Invalid Hierarchy Dependent in Single Employee. Choose other dependent.")
        {:hierarchy_type} ->
          add_error(changeset, :hierarchy, "Invalid Hierarchy Type")
        _ ->
          add_error(changeset, :hierarchy, "Invalid Hierarchy Parameters")
      end
    end
  end

  defp validate_hierarchy_type(changeset) do
    required = ["Married Employee", "Single Parent Employee", "Single Employee"]
    hierarchy_type = for changes <- changeset do
      Enum.any?(required, fn(x) -> x == changes["hierarchy_type"] end)
    end

    # MARRIED EMPLOYEE
    married_emp_hierarchy_rank = married_emp_hierarchy_rank(changeset)

    married_emp_hierarchy_dependent = married_emp_hierarchy_dependent(changeset)

    number_of_married_employee  = Enum.count(married_emp_hierarchy_rank)

    ranking_validation = ranking_validation(married_emp_hierarchy_rank, number_of_married_employee)

    married_spouse = Enum.count(married_emp_hierarchy_dependent, fn(x) -> x == "Spouse" end)
    married_child = Enum.count(married_emp_hierarchy_dependent, fn(x) -> x == "Child" end)
    married_parent = Enum.count(married_emp_hierarchy_dependent, fn(x) -> x == "Parent" end)
    married_sibling = Enum.count(married_emp_hierarchy_dependent, fn(x) -> x == "Sibling" end)

    married_one = Enum.count(married_emp_hierarchy_rank, fn(x) -> x == "1" end)
    married_two = Enum.count(married_emp_hierarchy_rank, fn(x) -> x == "2" end)
    married_three = Enum.count(married_emp_hierarchy_rank, fn(x) -> x == "3" end)
    married_four = Enum.count(married_emp_hierarchy_rank, fn(x) -> x == "4" end)

    is_valid_type = is_valid_type(hierarchy_type)

    is_valid_married_rank = is_valid_married_rank(
        married_one,
        married_two,
        married_three,
        married_four
    )

    is_valid_married_dependent = is_valid_married_dependent(
        married_spouse,
        married_child,
        married_parent,
        married_sibling
    )

    is_valid_married_ranking = is_valid_married_ranking(ranking_validation)

    # END OF MARRIED EMPLOYEE

    # SINGLE PARENT EMPLOYEE
    single_parent_emp_hierarchy_rank = single_parent_emp_hierarchy_rank(changeset)

    single_parent_emp_hierarchy_dependent = single_parent_emp_hierarchy_dependent(changeset)

    number_of_single_parent_employee = Enum.count(single_parent_emp_hierarchy_rank)

    single_parent_ranking_validation = single_parent_ranking_validation(
      single_parent_emp_hierarchy_rank,
      number_of_single_parent_employee
    )

    single_parent_child = Enum.count(single_parent_emp_hierarchy_dependent, fn(x) -> x == "Child" end)
    single_parent_parent = Enum.count(single_parent_emp_hierarchy_dependent, fn(x) -> x == "Parent" end)
    single_parent_sibling = Enum.count(single_parent_emp_hierarchy_dependent, fn(x) -> x == "Sibling" end)

    single_parent_one = Enum.count(single_parent_emp_hierarchy_rank, fn(x) -> x == "1" end)
    single_parent_two = Enum.count(single_parent_emp_hierarchy_rank, fn(x) -> x == "2" end)
    single_parent_three = Enum.count(single_parent_emp_hierarchy_rank, fn(x) -> x == "3" end)
    is_valid_type = if Enum.all?(hierarchy_type) do "ok" else "error" end

    is_valid_single_parent_rank = is_valid_single_parent_rank(
        single_parent_one,
        single_parent_two,
        single_parent_three
    )

    is_valid_single_parent_dependent = is_valid_single_parent_dependent(
        single_parent_child,
        single_parent_parent,
        single_parent_sibling
    )

    is_valid_single_parent_ranking = is_valid_single_parent_ranking(single_parent_ranking_validation)

    # END OF SINGLE PARENT EMPLOYEE

    # SINGLE EMPLOYEE
    single_emp_hierarchy_rank = single_emp_hierarchy_rank(changeset)

    single_emp_hierarchy_dependent = single_emp_hierarchy_dependent(changeset)

    number_of_single_employee  = Enum.count(single_emp_hierarchy_rank)

    single_ranking_validation = single_ranking_validation(
      single_emp_hierarchy_rank,
      number_of_single_employee
    )

    single_parent = Enum.count(single_emp_hierarchy_dependent, fn(x) -> x == "Parent" end)
    single_sibling = Enum.count(single_emp_hierarchy_dependent, fn(x) -> x == "Sibling" end)

    single_one = Enum.count(single_emp_hierarchy_rank, fn(x) -> x == "1" end)
    single_two = Enum.count(single_emp_hierarchy_rank, fn(x) -> x == "2" end)
    is_valid_type = if Enum.all?(hierarchy_type) do "ok" else "error" end
    is_valid_single_rank =
      if single_one <= 1 and single_two <= 1 do
        "single_rank_ok"
      else
        "single_rank_error"
      end
    is_valid_single_dependent =
      if single_parent <= 1 and single_sibling <= 1 do
        "single_dependent_ok"
      else
        "single_dependent_error"
      end
    is_valid_single_ranking =
      if Enum.member?(single_ranking_validation, true) do
        "single_ranking_error"
      else
        "single_ranking_ok"
      end
    # END OF SINGLE EMPLOYEE

    with "ok" <- is_valid_type,
         "married_ranking_ok" <- is_valid_married_ranking,
         "married_rank_ok" <- is_valid_married_rank,
         "married_dependent_ok" <- is_valid_married_dependent,
         "single_parent_ranking_ok" <- is_valid_single_parent_ranking,
         "single_parent_rank_ok" <- is_valid_single_parent_rank,
         "single_parent_dependent_ok" <- is_valid_single_parent_dependent,
         "single_ranking_ok" <- is_valid_single_ranking,
         "single_rank_ok" <- is_valid_single_rank,
         "single_dependent_ok" <- is_valid_single_dependent
    do
      true
    else
      "married_ranking_error" ->
        {:married_hierarchy_ranking}
      "married_dependent_error" ->
        {:married_hierarchy_dependent}
      "married_rank_error" ->
        {:married_hierarchy_rank}
      "single_parent_ranking_error" ->
        {:single_parent_hierarchy_ranking}
      "single_parent_dependent_error" ->
        {:single_parent_hierarchy_dependent}
      "single_parent_rank_error" ->
        {:single_parent_hierarchy_rank}
      "single_ranking_error" ->
        {:single_hierarchy_ranking}
      "single_dependent_error" ->
        {:single_hierarchy_dependent}
      "single_rank_error" ->
        {:single_hierarchy_rank}
      "error" ->
        {:hierarchy_type}
    end
  end

  defp married_emp_hierarchy_rank(changeset) do
    for %{"hierarchy_type" => "Married Employee"} = hierarchy <- changeset do
      hierarchy["ranking"]
    end
  end

  defp married_emp_hierarchy_dependent(changeset) do
    for %{"hierarchy_type" => "Married Employee"} = hierarchy <- changeset do
      hierarchy["dependent"]
    end
  end

  defp ranking_validation(married_emp_hierarchy_rank, number_of_married_employee) do
    for rank <- married_emp_hierarchy_rank do
      if String.to_integer(rank) > number_of_married_employee do
        true
      else
        false
      end
    end
  end

  defp is_valid_type(hierarchy_type) do
    if Enum.all?(hierarchy_type) do
      "ok"
    else
      "error"
    end
  end

  defp is_valid_married_rank(married_one, married_two, married_three, married_four) do
    if married_one <= 1 and married_two <= 1 and married_three <= 1 and married_four <= 1 do
      "married_rank_ok"
    else
      "married_rank_error"
    end
  end

  defp is_valid_married_dependent(married_spouse, married_child, married_parent, married_sibling) do
    if married_spouse <= 1 and married_child <= 1 and married_parent <= 1 and married_sibling <= 1 do
      "married_dependent_ok"
    else
      "married_dependent_error"
    end
  end

  defp is_valid_married_ranking(ranking_validation) do
    if Enum.member?(ranking_validation, true) do
      "married_ranking_error"
    else
      "married_ranking_ok"
    end
  end

  defp  single_parent_emp_hierarchy_rank(changeset) do
    for %{"hierarchy_type" => "Single Parent Employee"} = hierarchy <- changeset do
      hierarchy["ranking"]
    end
  end

  defp single_parent_emp_hierarchy_dependent(changeset) do
    for %{"hierarchy_type" => "Single Parent Employee"} = hierarchy <- changeset do
      hierarchy["dependent"]
    end
  end

  defp single_parent_ranking_validation(single_parent_emp_hierarchy_rank, number_of_single_parent_employee) do
    for rank <- single_parent_emp_hierarchy_rank do
      if String.to_integer(rank) > number_of_single_parent_employee do
        true
      else
        false
      end
    end
  end

  defp is_valid_single_parent_rank(single_parent_one, single_parent_two, single_parent_three) do
    if single_parent_one <= 1 and single_parent_two <= 1 and single_parent_three <= 1 do
      "single_parent_rank_ok"
    else
      "single_parent_rank_error"
    end
  end

  defp is_valid_single_parent_dependent(single_parent_child, single_parent_parent, single_parent_sibling) do
    if single_parent_child <= 1 and single_parent_parent <= 1 and single_parent_sibling <= 1 do
      "single_parent_dependent_ok"
    else
      "single_parent_dependent_error"
    end
  end

  defp is_valid_single_parent_ranking(single_parent_ranking_validation) do
    if Enum.member?(single_parent_ranking_validation, true) do
      "single_parent_ranking_error"
    else
      "single_parent_ranking_ok"
    end
  end

  defp single_emp_hierarchy_rank(changeset) do
    for %{"hierarchy_type" => "Single Employee"} = hierarchy <- changeset do
      hierarchy["ranking"]
    end
  end

  defp single_emp_hierarchy_dependent(changeset) do
    for %{"hierarchy_type" => "Single Employee"} = hierarchy <- changeset do
      hierarchy["dependent"]
    end
  end

  defp single_ranking_validation(single_emp_hierarchy_rank, number_of_single_employee) do
    for rank <- single_emp_hierarchy_rank do
      if String.to_integer(rank) > number_of_single_employee do
        true
      else
        false
      end
    end
  end

  defp hierarchy_field(params) do
    data = %{}
    hierarchy_types = %{
      hierarchy_type: :string,
      dependent: :string,
      ranking: :string
    }
    changeset =
      {data, hierarchy_types}
      |> Changeset.cast(params, Map.keys(hierarchy_types))
      |> Changeset.validate_required([
        :hierarchy_type,
        :dependent,
        :ranking
      ])
      |> validate_inclusion(:hierarchy_type,
        ["Married Employee",
        "Single Parent Employee",
        "Single Employee"])
      |> validate_dependents()

    changeset.valid?
  end

  defp validate_dependents(changeset) do
    if is_nil(changeset.changes[:hierarchy_type]) do
      changeset
    else
      cond do
      changeset.changes.hierarchy_type == "Married Employee" ->
        changeset =
          changeset
          |> validate_inclusion(:dependent,
                                ["Spouse", "Parent", "Child", "Sibling"])
          |> validate_inclusion(:ranking, ["1", "2", "3", "4"])
      changeset.changes.hierarchy_type == "Single Parent Employee" ->
        changeset =
          changeset
          |> validate_inclusion(:dependent, ["Parent", "Child", "Sibling"])
          |> validate_inclusion(:ranking, ["1", "2", "3"])
      changeset.changes.hierarchy_type == "Single Employee" ->
        changeset =
          changeset
          |> validate_inclusion(:dependent, ["Parent", "Sibling"])
          |> validate_inclusion(:ranking, ["1", "2"])
      true ->
        add_error(changeset, :hierarchy_type, "is invalid.")
      end
    end
  end

   # Validate All Fields using Numbers
  defp validate_all_number_fields(changeset_field, field, changeset) do
    with true <- validate_a_number_field(changeset_field, field)
      do
        changeset
      else
        {:invalid_number_format, field} ->
        add_error(changeset, field, "Must be a number.")
      end
  end

  defp validate_a_number_field(numbers, field_name) do
      valid_format = validate_numbers(numbers)
      if valid_format do
        true
      else
        {:invalid_number_format, field_name}
      end
  end

  def validate_number_field(numbers) do
    for number <- numbers do
      valid_format = validate_numbers(number)
      if valid_format do
        true
      else
        false
      end
    end
  end

  defp validate_numbers(string) do
    Regex.match?(~r/^[0-9]*(\.[0-9]{1,90})?$/, string)
  end
  # End of Validate All Fields using Numbers

  defp get_product!(id), do: Repo.get(Product, id)

  defp valid_approver?(params) do
    data = %{}
    types = %{
      name: :string,
      designation: :string,
      department: :string,
      telephone: :string,
      mobile: :string,
      email: :string
    }
    changeset =
      {data, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([
        :name,
        :department,
        :mobile,
        :email
      ])
      |> Changeset.validate_format(
        :email,
        ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/
      )

    # Changes
    if changeset.valid? do
      changeset = validate_all_number_fields(changeset.changes.mobile,
                                             :mobile, changeset)
      changeset.valid?
    else
      changeset.valid?
    end
  end

  def get_account_group_list(id) do
    AccountGroup
    |> Repo.get(id)
    |> Repo.preload([
      :account,
      :payment_account,
      :industry,
      :account_hierarchy_of_eligible_dependents,
      :account_group_address,
      account_group_contacts: [
        [contact: :phones]
      ]
    ])
  end

  defp insert_account_contact(account_group_id, contact_array) do
    for contact <- contact_array do
      contact_params = %{
        account_group_id: account_group_id,
        contact_id: contact.id
      }
      insert_account_group_contact(contact_params)
    end
  end

  defp insert_address2(params, account_group_id) do
    if params["is_billing_same_with_company"] do
      company_params = %{
        line_1: params["company_address"]["line_1"],
        line_2: params["company_address"]["line_2"],
        city: params["company_address"]["city"],
        province: params["company_address"]["province"],
        country: params["company_address"]["country"],
        region: params["company_address"]["region"],
        postal_code: params["company_address"]["postal_code"],
        account_group_id: account_group_id,
        type: "Account Address",
        is_check: true
      }
      insert_account_group_address(company_params)
    else
      company_params = %{
        line_1: params["company_address"]["line_1"],
        line_2: params["company_address"]["line_2"],
        city: params["company_address"]["city"],
        province: params["company_address"]["province"],
        country: params["company_address"]["country"],
        region: params["company_address"]["region"],
        postal_code: params["company_address"]["postal_code"],
        account_group_id: account_group_id,
        type: "Account Address",
        is_check: false
      }
      billing_params = %{
        line_1: params["billing_address"]["line_1"],
        line_2: params["billing_address"]["line_2"],
        city: params["billing_address"]["city"],
        province: params["billing_address"]["province"],
        country: params["billing_address"]["country"],
        region: params["billing_address"]["region"],
        postal_code: params["billing_address"]["postal_code"],
        account_group_id: account_group_id,
        type: "Billing Address",
        is_check: false
      }
      insert_account_group_address(company_params)
      insert_account_group_address_billing(billing_params)
    end
  end

  defp validate_industry_code(changeset) do
    if is_nil(changeset.changes[:industry_code]) do
      changeset
    else
      industry = Repo.get_by(Industry, code:
                             Changeset.get_field(changeset, :industry_code))
      if industry do
        Map.put(changeset, :changes, Map.put(changeset.changes,
                                             :industry_id, industry.id))
      else
        add_error(changeset, :industry_code, "Invalid industry code")
      end
    end
  end

  # Insert Account Group
  defp insert_account_group(params) do
    params =
      params.changes
      # |> Map.put(:original_effective_date, params.changes.effective_date)

    %AccountGroup{}
    |> AccountGroup.changeset(params)
    |> Repo.insert()
  end

  # Insert Account
  defp insert_account(params) do
    params =
      params
      |> Map.merge(%{
        "status" => "Pending",
        "step" => 7,
        "major_version" => 1,
        "minor_version" => 0,
        "build_version" => 0,
        "start_date" => String.replace(params["effective_date"], "‑", "-"),
        "end_date" => String.replace(params["expiry_date"], "‑", "-")
      })

    {:ok, account} =
      %Account{}
      |> Account.changeset(params)
      |> Repo.insert()

    Innerpeace.Db.Base.AccountContext.active_account(params["account_group_id"])
    Innerpeace.Db.Base.AccountContext.expired_account(params["account_group_id"])

    {:ok, account}
  end

  defp insert_account_active(params) do
    params =
      params
      |> Map.merge(%{
        "status" => "Active",
        "step" => 7,
        "major_version" => 1,
        "minor_version" => 0,
        "build_version" => 0,
        "start_date" => String.replace(params["effective_date"], "‑", "-"),
        "end_date" => String.replace(params["expiry_date"], "‑", "-")
      })

    %Account{}
    |> Account.changeset(params)
    |> Repo.insert()
  end

  # Insert Account Group Address
  defp insert_account_group_address(params) do
    %AccountGroupAddress{}
    |> AccountGroupAddress.changeset(params)
    |> Repo.insert()
  end

  defp insert_account_group_address_billing(params) do
    %AccountGroupAddress{}
    |> AccountGroupAddress.changeset_api_billing(params)
    |> Repo.insert()
  end

  # Insert Account Group Contact
  defp insert_account_group_contact(params) do
    %AccountGroupContact{}
    |> AccountGroupContact.changeset(params)
    |> Repo.insert()
  end

  # Insert Contact
  def insert_contact(params, contacts) when is_list(contacts) do

    if Map.has_key?(params, "contact") do
      for contact <- params["contact"] do

        # Changes
        if is_nil(contact["ctc_date_issued"]) do
          ctc_date = ""
        else
          ctc_date = String.replace(contact["ctc_date_issued"], "‑", "-")
        end

        # Changes
        if is_nil(contact["passport_date_issued"]) do
          passport_date = ""
        else
          passport_date = String.replace(contact["passport_date_issued"],
                                         "‑", "-")
        end

        # Changes
        contact =
          contact
          |> Map.put_new("first_name", contact["full_name"])
          |> Map.put_new("last_name", contact["full_name"])
          |> Map.put("ctc_date_issued", ctc_date)
          |> Map.put("passport_date_issued", passport_date)

        inserted_contact =
          %Contact{}
          |> Contact.changeset(contact)
          |> Repo.insert!()

        if Map.has_key?(contact, "mobile") do
          insert_mobile(%{
            contact_id: inserted_contact.id,
            number: contact["mobile"],
            type: "mobile",
            country_code: contact["mobile_country_code"]
          })
        end

        if Map.has_key?(contact, "telephone") do
          insert_telephone(%{
            contact_id: inserted_contact.id,
            number: contact["telephone"],
            type: "telephone",
            country_code: contact["tel_country_code"],
            area_code: contact["tel_area_code"],
            local: contact["tel_local"]
          })
        end

        if Map.has_key?(contact, "fax") do
          insert_fax(%{
            contact_id: inserted_contact.id,
            number: contact["fax"],
            type: "fax",
            country_code: contact["fax_country_code"],
            area_code: contact["fax_area_code"],
            local: contact["fax_local"]
          })
        end

        inserted_contact
      end
    end
  end

  def insert_contact(params, contacts) do
    []
  end

  defp insert_mobile(params) do
    Enum.each(Enum.with_index(params.number, 0), fn({number, counter}) ->
      country_code =
      if is_nil(params.country_code) do
        "+63"
      else
        Enum.at(params.country_code, counter)
      end

      phone_params = %{
        type: params.type,
        number: number,
        contact_id: params.contact_id,
        country_code: country_code
      }

      %Phone{}
      |> Phone.changeset(phone_params)
      |> Repo.insert!()
    end)
  end

  defp insert_telephone(params) do
    Enum.each(Enum.with_index(params.number, 0), fn({number, counter}) ->
      local =
        if is_nil(params.local) || params.local == "" do
          nil
        else
          Enum.at(params.local, counter)
        end
      area_code =
        if is_nil(params.area_code) || params.area_code == "" do
          nil
        else
          Enum.at(params.area_code, counter)
        end
      country_code =
        if is_nil(params.country_code) do
          "+63"
        else
          Enum.at(params.country_code, counter)
        end

      phone_params = %{
        type: params.type,
        number: number,
        contact_id: params.contact_id,
        country_code: country_code,
        area_code: area_code,
        local: local
      }

      %Phone{}
      |> Phone.changeset(phone_params)
      |> Repo.insert!()
    end)
  end

  defp insert_fax(params) do
    Enum.each(Enum.with_index(params.number, 0), fn({number, counter}) ->
      local =
        if is_nil(params.local) || params.local == "" do
          nil
        else
          Enum.at(params.local, counter)
        end
      area_code =
        if is_nil(params.area_code) || params.area_code == "" do
          nil
        else
          Enum.at(params.area_code, counter)
        end
      country_code =
        if is_nil(params.country_code) do
          "+63"
        else
          Enum.at(params.country_code, counter)
        end

      phone_params = %{
        type: params.type,
        number: number,
        contact_id: params.contact_id,
        country_code: country_code,
        area_code: area_code,
        local: local
      }

      %Phone{}
      |> Phone.changeset(phone_params)
      |> Repo.insert!()
    end)
  end

  defp validate_products(changeset) do
    if is_nil(changeset.changes[:products]) do
      changeset
    else
      products = Changeset.get_field(changeset, :products)
      valid_product = product_field(products)
      with true <- valid_product,
           true <- validate_product_list(products)
      do
        changeset
      else
        {:at_least_one} ->
          add_error(changeset, :products,
                    "At least one plan code is required")
        _ ->
          add_error(changeset, :products, "Invalid plan parameters")
      end
    end
  end

  defp validate_coverage_fund(changeset) do
    if Map.has_key?(changeset.changes, :coverage_fund) do
      coverage_funds = Changeset.get_field(changeset, :coverage_fund)
      valid_coverage_fund = for coverage_fund <- coverage_funds, do: coverage_fund_field(changeset, coverage_fund)
      coverage_count =
        valid_coverage_fund
        |> Enum.uniq()
        |> List.delete(false)
        |> List.delete(true)
        |> List.flatten()

      with false <- Enum.member?(valid_coverage_fund, false),
             0 <- Enum.count(coverage_count)
      do
        changeset
      else
        _ ->
            add_error(changeset, :coverage_fund, "Invalid coverage fund parameters")
      end

    else
      changeset
    end
  end

  defp coverage_fund_field(primary_changeset, changeset) do
    data = %{}
    general_types = %{
      coverage: {:array, :string},
      revolving_fund: :string,
      replenish_threshold: :string
    }
    coverage_changeset =
      {data, general_types}
      |> Changeset.cast(changeset, Map.keys(general_types))
      |> Changeset.validate_required([
        :coverage,
        :revolving_fund,
        :replenish_threshold
      ])

    if coverage_changeset.valid? do
      coverage_fund_field2(coverage_changeset)
    else
      false
    end
  end

  defp coverage_fund_field2(changeset) do
    coverage_id =
      Enum.map(changeset.changes[:coverage], &(get_coverage_by_name(&1)))
    coverage_ids = Enum.uniq(coverage_id)

    if Enum.member?(coverage_ids, nil) do
      false
    else
      coverage_fund_field3(changeset)
    end
  end

  defp coverage_fund_field3(changeset) do
    changeset =
      validate_all_number_fields(
        changeset.changes[:replenish_threshold],
        :replenish_threshold,
        changeset
      )
    changeset =
      validate_all_number_fields(
        changeset.changes[:revolving_fund],
        :revolving_fund,
        changeset
      )

    if changeset.valid? do
      true
    else
      changeset.errors
    end
  end

  def insert_coverage_fund(params, account_group) do
    if not is_nil(params) do
      for params <- params do
        coverage_id = Enum.map(params["coverage"], &(get_coverage_by_name(&1)))
        coverage_ids = Enum.uniq(coverage_id)
        Enum.each(coverage_ids, fn(coverage) ->
          params =
            params
            |> Map.put("coverage_id", coverage.id)
            |> Map.put("replenish_threshold", params["replenish_threshold"])
            |> Map.put("revolving_fund", params["revolving_fund"])
            |> Map.put("account_group_id", account_group.id)

          check_funds(params)
        end)
      end
    end
  end

  defp check_funds(params) do
    funds = get_cov_funds(params)
    if Enum.empty?(funds) do
      insert_account_coverage_fund(params)
    end
  end

  defp get_cov_funds(params) do
    AccountGroupCoverageFund
    |> where([agcf],
             agcf.coverage_id == ^params["coverage_id"] and
             agcf.replenish_threshold == ^params["replenish_threshold"] and
             agcf.revolving_fund == ^params["revolving_fund"] and
             agcf.account_group_id == ^params["account_group_id"]
            )
    |> Repo.all()
  end

  defp insert_financial(params, account_group) do
    vat_status =
      if params["vat_status"] == "" or is_nil(params["vat_status"]) do
        ""
      else
        String.replace(params["vat_status"], "‑", "-")
      end

    if params["payment_mode"] == "Check" do
      params_check = %{
        "mode_of_payment" => params["payment_mode"],
        "account_group_id" => account_group.id,
        "payee_name" => params["payee_name"],
        "account_tin" => params["tin"],
        "vat_status" => vat_status,
        # "p_sched_of_payment" => params["principal_schedule_payment"],
        # "d_sched_of_payment" => params["dependent_schedule_payment"],
        "previous_carrier" => params["previous_carrier"],
        "attached_point" => params["attached_point"],
        # "revolving_fund" => params["revolving_fund"],
        # "threshold" => params["replenish_threshold"],
        "authority_debit" => params["authority_to_debit"],
        "funding_arrangement" => params["funding_arrangement"],
        "attached_point" => params["attached_point"]
      }
      insert_payment_account(params_check)
      if params["special_approval"]["is_funding_source"] do
        update_account_group_financial(
          account_group, %{payee_name: params["payee_name"]})
      else
        update_account_group_financial(
          account_group,
          %{payee_name: params["special_approval"]["payee_name"]})
      end
    else
      params_electronic = %{
        "mode_of_payment" => params["payment_mode"],
        "account_group_id" => account_group.id,
        "bank_account" => params["bank_name"],
        "account_tin" => params["tin"],
        "vat_status" => vat_status,
        # "p_sched_of_payment" => params["principal_schedule_payment"],
        # "d_sched_of_payment" => params["dependent_schedule_payment"],
        "previous_carrier" => params["previous_carrier"],
        "attached_point" => params["attached_point"],
        # "revolving_fund" => params["revolving_fund"],
        # "threshold" => params["replenish_threshold"],
        "authority_debit" => params["authority_to_debit"],
        "funding_arrangement" => params["funding_arrangement"],
        "attached_point" => params["attached_point"]
      }
      params_bank = %{
        account_name: params["bank_name"],
        account_no: params["bank_account_number"],
        branch: params["bank_branch"],
        account_group_id: account_group.id
      }
      insert_payment_account(params_electronic)
      insert_bank(params_bank)
      if params["special_approval"]["is_funding_source"] do
        financial_params = %{
          account_no: params["bank_account_number"],
          account_name: params["bank_name"],
          branch: params["bank_branch"]
        }
      else
        financial_params = %{
          account_no: params["special_approval"]["bank_account_number"],
          account_name: params["special_approval"]["bank_name"],
          branch: params["special_approval"]["bank_branch"]
        }
      end
      update_account_group_financial(account_group, financial_params)
    end
  end

  defp insert_approvers(approvers, account_group_id) do
    if is_nil(approvers) do
      nil
    else
      for approver <- approvers do
        insert_account_group_approval(Map.put(approver, "account_group_id",
                                              account_group_id))
      end
    end
  end

  defp insert_products(changeset, account_id) do
    if is_nil(changeset.changes[:products]) do
      changeset
    else
      product_ids = Enum.map(changeset.changes.products["code"],
                             &(get_product_by_code(&1)))
      for {product_id, index} <- Enum.with_index(product_ids) do
        rank = index + 1
        account = get_account!(account_id)
          keys = [
            :name,
            :description,
            :type,
            :limit_applicability,
            :limit_type,
            :limit_amount,
            :standard_product
          ]
        product_id
        |> get_product()
        |> Map.take(keys)
        |> Map.put(:rank, rank)
        |> Map.merge(%{account_id: account_id, product_id: product_id})
        |> create_account_product

        update_account_version(
          account, %{"minor_version" => account.minor_version + 1}
        )
      end
    end
  end

  defp insert_fulfillments(fulfillments, account_group_id) do
    for fulfillment <- fulfillments do
      {:ok, fulfillment_card} = insert_fulfillment(fulfillment)
      # fulfillment_id = get_fulfillment_by_code(
      #   fulfillment["product_code_name"]
      # )
      params = %{
        account_group_id: account_group_id,
        fulfillment_id: fulfillment_card.id
      }
      insert_account_group_fulfillment(params)
    end
  end

  # Insert Fulfillment
  def insert_fulfillment(params) do
    %FulfillmentCard{}
    |> FulfillmentCard.changeset_card(params)
    |> Repo.insert()
  end

  # Insert Account Fulfillment
  def insert_account_group_fulfillment(params) do
    %AccountGroupFulfillment{}
    |> AccountGroupFulfillment.changeset(params)
    |> Repo.insert()
  end

  # Insert Contact Phones
  def insert_phone(params) do
    %Phone{}
    |> Phone.changeset(params)
    |> Repo.insert()
  end

  # Insert Payment Account
  def insert_payment_account(params) do
    %PaymentAccount{}
    |> PaymentAccount.changeset_account(params)
    |> Repo.insert()
  end

  # Insert Bank
  def insert_bank(params) do
    %Bank{}
    |> Bank.changeset(params)
    |> Repo.insert()
  end

  # Insert Bank Branch
  def insert_bank_branch(params) do
    %BankBranch{}
    |> BankBranch.changeset(params)
    |> Repo.insert()
  end

  # Insert Account Group Approval
  def insert_account_group_approval(params) do
    %AccountGroupApproval{}
    |> AccountGroupApproval.changeset(params)
    |> Repo.insert()
  end

  def industry_validated?(industry_id) do
    Industry
    |> where([i], i.id == ^industry_id)
    |> Repo.one()
  end

  defp insert_hierarchy_of_eligible_dependent(hoeds, account_group_id) do
    if is_nil(hoeds) do
      hoeds
    else
      for hoed <- hoeds do
        params = %{
          account_group_id: account_group_id,
          hierarchy_type: hoed["hierarchy_type"],
          dependent: hoed["dependent"],
          ranking: hoed["ranking"]
        }

        %AccountHierarchyOfEligibleDependent{}
        |> AccountHierarchyOfEligibleDependent.changeset(params)
        |> Repo.insert
      end
    end
  end

  def valid_uuid?(id) do
    case UUID.cast(id) do
      {:ok, id} ->
        {true, id}
      :error ->
        {:invalid_id}
    end
  end

  def get_account_group_by_code(code) do
    AccountGroup
    |> where([ag], ag.code == ^code)
    |> Repo.one()
    |> Repo.preload([
      members: [
        dependents: {from(m in Member,
                          order_by: [desc: m.birthdate]),
          :skipped_dependents},
        products: [account_product: :product]],
      account_hierarchy_of_eligible_dependents: from(
        hoed in AccountHierarchyOfEligibleDependent,
        order_by: [hoed.hierarchy_type, hoed.ranking]
      ),
      account: from(a in Account, where: a.status == "Active")
    ])
    |> Repo.preload([account: :account_group])
  end

  defp get_all_account_codes do
    AccountGroup
    |> select([ag], ag.code)
    |> Repo.all()
  end

  def get_product_by_code(code) do
    Product
    |> where([b], b.code == ^code)
    |> select([b], b.id)
    |> Repo.one()
  end

  defp get_fulfillment_by_code(product_code_name) do
    FulfillmentCard
    |> where([fc], fc.product_code_name == ^product_code_name)
    |> select([fc], fc.id)
    |> Repo.one()
  end
  # END OF API

  # Start of Account Renewal
  def validate_renew_account(conn, params) do
    if is_nil(conn) do
      {:not_authorized}
    else
      with {:ok, changeset} <- validate_ra_params_level1(params),
           account <- renew_account(conn, changeset)
      do
        {:ok, account}
      else
        {:error, changeset} ->
          {:error, changeset}
        _ ->
          {:not_found}
      end
    end
  end

  def validate_ra_params_level1(params) do
    data = %{}
    parameter_types = %{
      code: :string,
      effectivity_date: Ecto.Date,
      expiry_date: Ecto.Date,
    }
    changeset =
      {data, parameter_types}
      |> Changeset.cast(params, Map.keys(parameter_types))

    if changeset.valid? do
      validate_ra_params_level1_1(changeset)
    else
      {:error, changeset}
    end
  end

  defp validate_ra_params_level1_1(changeset) do
    changeset =
      changeset
      |> check_parameters(:code, "code")
      |> check_parameters(:effectivity_date, "effectivity date")
      |> check_parameters(:expiry_date, "expiry date")

    if changeset.valid? do
      validate_ra_params_level2(changeset)
    else
      {:error, changeset}
    end
  end

  defp validate_ra_params_level2(changeset) do
    changeset =
      changeset
      |> validate_code
      |> validate_ra_date(:effectivity_date)
      |> validate_ra_date(:expiry_date)

    if changeset.valid? do
      validate_ra_params_level3(changeset)
    else
      {:error, changeset}
    end
  end

  defp validate_ra_params_level3(changeset) do
    changeset =
      changeset
      |> validate_account_status
      |> check_effectivity_date
      |> check_expiry_date

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp check_parameters(changeset, field, field_string) do
    field_val = changeset.changes[field]
    if field_val == nil or field_val == "" do
      add_error(changeset, field, "Please enter " <> field_string <> ".")
    else
      changeset
    end
  end

  defp check_field(param, field) do
    if param == nil or param == "" do
      {:error, field}
    else
      true
    end
  end

  defp validate_code(changeset) do
    code = changeset.changes[:code]
    account = get_api_account_by_code(code)

    if is_nil(account) do
      add_error(changeset, :code, "Account code doesn't exist.")
    else
      if account.status == "For Activation" do
        add_error(changeset, :code, "Account has a pending renewal setup.")
      else
        validate_code_params(changeset)
      end
    end
  end

  defp validate_code_params(changeset) do
    code = changeset.changes[:code]
    account = get_api_account_by_code(code)
    with true <- check_field(account.status, :status),
         true <- check_field(account.start_date, :effectivity_date),
         true <- check_field(account.end_date, :expiry_date)
    do
      changeset
    else
      {:error, :status} ->
        add_error(changeset, :code, "Account's status is invalid.")
      {:error, :effectivity_date} ->
        add_error(changeset, :code, "Account's effectivity date is invalid.")
      {:error, :expiry_date} ->
        add_error(changeset, :code, "Account's expiry date is invalid.")
    end
  end

  defp validate_ra_date(changeset, field) do
    date = Ecto.Date.to_string(changeset.changes[field])
    date_array = String.split(date, "-")

    with true <- String.length(Enum.at(date_array, 0)) == 4,
         true <- String.length(Enum.at(date_array, 1)) == 2,
         true <- String.length(Enum.at(date_array, 2)) == 2,
         true <- validate_number(Enum.at(date_array, 0)),
         true <- validate_number(Enum.at(date_array, 1)),
         true <- validate_number(Enum.at(date_array, 2)),
         true <- String.to_integer(Enum.at(date_array, 1)) <= 12,
         true <- String.to_integer(Enum.at(date_array, 2)) <= 31
    do
      changeset
    else
      false ->
        add_error(changeset, field, "Invalid date format.")
    end
  end

  defp validate_account_status(changeset) do
    code = changeset.changes[:code]
    account = get_api_account_by_code(code)
    if account.status == "Active" or account.status == "Lapsed" do
      changeset
    else
      add_error(changeset, :code,
                "The status of account should be active or lapsed to renew.")
    end
  end

  defp check_effectivity_date(changeset) do
    effectivity_date = Ecto.Date.cast!(changeset.changes[:effectivity_date])
    code = changeset.changes[:code]
    account = get_api_account_by_code(code)
    end_date = account.end_date

    case Ecto.Date.compare(effectivity_date, end_date) do
      :gt ->
        changeset
      _ ->
        add_error(changeset, :effectivity_date, "Effective date should be beyond the current expiry date of the account.")
    end
  end

  defp check_expiry_date(changeset) do
    effectivity_date = Ecto.Date.cast!(changeset.changes[:effectivity_date])
    expiry_date = Ecto.Date.cast!(changeset.changes[:expiry_date])

    case Ecto.Date.compare(effectivity_date, expiry_date) do
      :lt ->
        changeset
      :gt ->
        add_error(changeset, :expiry_date, "Expiry date should be beyond the new effective date of the account.")
      :eq ->
        add_error(changeset, :expiry_date, "Expiry date should be beyond the new effective date of the account.")
    end
  end

  defp validate_number(string) do
    Regex.match?(~r/^[0-9]*$/, string)
  end

  defp renew_account(conn, changeset) do
    params = changeset.changes
    user_id = conn.id
    account = get_api_account_by_code(params.code)
    latest = AccountContext.get_latest_account(account.account_group_id)

    params =
      account
      |> Map.take([:step, :account_group_id])
      |> Map.put(:status, "For Activation")
      |> Map.put(:created_by, user_id)
      |> Map.put(:updated_by, user_id)
      |> Map.put(:major_version, latest.major_version + 1)
      |> Map.put(:minor_version, 0)
      |> Map.put(:build_version, 0)
      |> Map.put(:start_date, changeset.changes.effectivity_date)
      |> Map.put(:end_date, changeset.changes.expiry_date)

    new_account =
      %Account{}
      |> Account.changeset_api_renew(params)
      |> Repo.insert!()

    account_group = AccountContext.get_account_group(params.account_group_id)

    rl_params = %{
      account_code: account_group.code,
      account_name: account_group.name
    }

    AccountContext.create_renew_logs(
      params.account_group_id,
      conn,
      rl_params
    )

    AccountContext.clone_account_product(account, new_account)
    new_account
  end

  defp get_api_account_by_code(code) do
    account_group =
      AccountGroup
      |> where([a], a.code == ^code)
      |> Repo.one
      |> Repo.preload([:account])

    if is_nil(account_group) do
      nil
    else
      AccountContext.get_latest_account(account_group.id)
    end
  end

  defp create_api_renew(attrs \\ %{}) do
    %Account{}
    |> Account.changeset_api_renew(attrs)
    |> Repo.insert()
  end
  # End of Account Renewal

  def get_account_latest do
    date_now = DateTime.utc_now()
    date = "#{date_now.year}-#{date_now.month}-#{date_now.day}"
    {:ok, start_date} = Date.new(2018, 1, 16)

    query = (
      from ag in AccountGroup,
      join: a in Account, on: a.account_group_id == ag.id,
      select: (%{:code => ag.code,
        :name => ag.name,
        :date_created => ag.inserted_at
      }),
      where:
      a.step == ^"7" and
      is_nil(ag.replicated) and
      a.status == "Active"
    )

    data = Repo.all(query)

    result = for d <- data do
      d_date =
        d.date_created
        |> DateTime.to_date()

      case Date.compare(d_date, start_date) do
        :lt ->
          nil
        _ ->
          d
      end
    end

    result =
      result
      |> Enum.uniq
      |> List.delete(nil)
  end

  # Start of put /accounts/replicated
  def set_account_replicated(code) do
    if is_nil(code) do
      {:error, "Parameter is invalid"}
    else
      account_group = get_account_group_by_code(code)

      if is_nil(account_group) do
        {:error, "Code doesn't exist."}
      else
        if account_group.replicated == nil do
          account_group
          |> AccountGroup.changeset_update_replicated(%{replicated: "y"})
          |> Repo.update()
        else
          {:error, "Code has already been tagged as replicated."}
        end
      end
    end
  end
  # End of put /accoutns/replicated

  #add product api
  def validate_insert_product(params) do
    with {:ok, changeset} <- validate_general_product(params),
         {:ok, account} <- validate_account(changeset),
         {:ok} <- validate_account_products(changeset, account.id) do
        account
        account
        |> Map.put(:product_codes, changeset.changes.product_codes)
    else
      {:error, changeset} ->
        Map.put(changeset.changes, :errors, UtilityContext.changeset_errors_to_string2(changeset.errors))
    end
  end

  def validate_general_product(params) do
    data = %{}
    general_types = %{
      account_code: :string,
      product_codes: {:array, :string}
    }
    changeset =
      {data, general_types}
      |> Changeset.cast(params, Map.keys(general_types))
      |> Changeset.validate_required([
        :account_code,
        :product_codes
      ])
    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp validate_account(changeset) do
    account_group = get_account_group_by_code(changeset.changes.account_code)
    if is_nil(account_group) do
      changeset =
      add_error(changeset, :account_code, "#{changeset.changes.account_code} does not exist")
      {:error, changeset}
    else
      account =
        Enum.at(account_group.account, 0)
      {:ok, account}
    end
  end

  defp validate_account_products(changeset, account_id) do
    if is_nil(changeset.changes.product_codes) do
      changeset = changeset
    else
      product_ids = Enum.map(changeset.changes.product_codes,
                             &(get_product_by_code(&1)))
      products = for {product_id, index} <- Enum.with_index(product_ids) do
        rank = index + 1
        account = get_account!(account_id)
        cond do
          is_nil(product_id) ->
            "#{Enum.at(changeset.changes.product_codes, index)} not found! "
          not Enum.empty?(get_account_product_by_code(account_id, Enum.at(changeset.changes.product_codes, index))) ->
            "#{Enum.at(changeset.changes.product_codes, index)} already in account's plan! "
          true ->
            valid_product?(account, product_id, rank)
        end
      end

      products =
        products
        |> Enum.uniq()
        |> List.delete({:ok})

      if Enum.empty?(products) do
        changeset
      else
        changeset =
          add_error(changeset, :Product_code, "#{products}")
      end
    end

    if changeset.valid? do
      {:ok}
    else
      {:error, changeset}
    end
  end

  def insert_account_product(params) do
    with {:ok, changeset} <- validate_general_product(params),
         {:ok, account} <- validate_account(changeset) do
      product_ids = Enum.map(changeset.changes.product_codes,
                       &(get_product_by_code(&1)))
      products = for {product_id, index} <- Enum.with_index(product_ids) do
        rank = index + 1
        account = get_account!(account.id)

        keys = [
          :name,
          :description,
          :type,
          :limit_applicability,
          :limit_type,
          :limit_amount,
          :standard_product
        ]

        product_id
        |> get_product()
        |> Map.take(keys)
        |> Map.put(:rank, rank)
        |> Map.merge(%{account_id: account.id, product_id: product_id})
        |> create_account_product

        update_account_version(
          account, %{"minor_version" => account.minor_version + 1}
        )
      end
    else
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def valid_product?(account, product_id, rank) do
    product = get_product(product_id)
    account_coverage_funds =
      Enum.map(
        account.account_group.account_group_coverage_funds,
        &(&1.coverage_id)
      )
    account_coverage_funds = account_coverage_funds |> Enum.uniq()
    aso_product_coverages =
      product.product_coverages
      |> Enum.filter(&(&1.funding_arrangement == "ASO"))
      |> Enum.map(&(&1.coverage_id))
    if Enum.empty?(aso_product_coverages -- account_coverage_funds) do
      peme = Enum.map(account.account_products, fn(x) ->
        x.product.product_category
      end)

      if Enum.member?(peme, "PEME Plan") and product.product_category == "PEME Plan" do
        "#{product.code} cannot be added. Account must have one PEME Plan only. "
      else
        {:ok}
      end
    else
      "#{product.code} cannot be added. Coverages in the following plan must have a Coverage Fund set up. "
    end
  end


  def get_account_group_by_code_V2(code) do
    AccountGroup
    |> where([ag], ag.code == ^code)
    |> Repo.one()
    |> Repo.preload([
      members: [
        dependents: {from(m in Member,
          order_by: [desc: m.birthdate]),
          :skipped_dependents},
        products: [account_product: :product]],
      account_hierarchy_of_eligible_dependents: from(
        hoed in AccountHierarchyOfEligibleDependent,
        order_by: [hoed.hierarchy_type, hoed.ranking]
      ),
      account: from(a in Account, where: a.status == "Active")
    ])
    |> Repo.preload([account: :account_group])
  end


  def get_account_V2!(id) do
    Account
    |> Repo.get(id)
    |> Repo.preload([[account_products: :product], :account_logs, [account_group: :account_group_coverage_funds]])

    rescue
      e in RuntimeError -> nil
      Ecto.NoResultsError -> nil
      Ecto.MultipleResultsError -> nil
  end



  def renew_account_join(code, major_version, minor_version, build_version) do
      account =
       Account
       |> join(:inner, [a], ag in AccountGroup, a.account_group_id == ag.id)
       |> where([a, ag], ag.code == ^code and a.major_version == ^major_version and a.minor_version == ^minor_version and a.build_version == ^build_version)
       |> select([a], a.id)
       |> Repo.one()

   end

   def create_renew(attrs \\ %{}) do
    %Account{}
    |> Account.changeset_renew_sap_api(attrs)
    |> Repo.insert()
  end


 def get_latest_account(account_group_id) do
    Account
    |> where([a], a.account_group_id == ^account_group_id)
    |> order_by([a], desc: a.inserted_at)
    |> limit(1)
    |> Repo.one
 end

 def get_latest_active_account(account_group_id) do
    Account
    |> where([a], a.account_group_id == ^account_group_id and a.status == "Active" or a.account_group_id == ^account_group_id and a.status == "Lapsed")
    |> order_by([a], desc: a.inserted_at)
    |> limit(1)
    |> Repo.one

 end


  def get_latest_for_renewal_account(account_group_id) do
    Account
    |> where([a], a.account_group_id == ^account_group_id and a.status == "For Renewal")
    |> order_by([a], desc: a.inserted_at)
    |> limit(1)
    |> Repo.one

  end



  def get_major_version(version) do
    version
    |> String.split(".")
    |> List.first()


  end

  def get_minor_version(version) do
    version
    |> String.split(".")
    |> Enum.at(1)

  end


  def get_build_version(version) do
    version
    |> String.split(".")
    |> List.last()


  end

  def get_account_group(id) do
    AccountGroup
    |> Repo.get(id)
    |> check_accg()
  end


 defp check_accg(ag) when is_nil(ag), do: {:error, "Account not found"}


  defp check_accg(ag) do
    ag
    |> Repo.preload([
      :account,
      :account_logs,
      :account_group_address,
      :contacts,
      :payment_account,
      :members,
      :industry,
      :bank,
      account_group_contacts: [
        contact: [:phones, :fax]]
    ])
  end


  def clone_account_product_v2(old_account, new_account) do
    ap =
      AccountProduct
      |> where([ap], ap.account_id == ^old_account.id)
      |> select([ap], %{product_id: ap.product_id})
      |> Repo.all()
    if Enum.empty?(ap) == false do
      Enum.each(ap, fn(product) ->
        product.product_id
        |> get_product()
        |> Map.from_struct
        |> Map.put(:product_id, product.product_id)
        |> Map.put(:account_id, new_account.id)
        |> create_account_product
      end)
    end
  end

  def validate_renew_account_fields(account, latest_account, params) do
    start_date = Ecto.Date.cast!(params["effectivity_date"])
    end_date = Ecto.Date.cast!(params["expiry_date"])

    # new_start_date =
    #   ((Ecto.Date.to_erl(latest_account.end_date) |> :calendar.date_to_gregorian_days) + 1)

    # new_start_date =
    #   new_start_date
    #   |> :calendar.gregorian_days_to_date
    #   |> Ecto.Date.cast!

    case Ecto.Date.compare(start_date, account.end_date) do
      :gt ->
        {:ok, start_date}
      :lt ->

        {:start_date_error, start_date}
      :eq ->

        {:start_date_error, start_date}
      _ ->
        {:start_date_error, start_date}

    end
  end

  def validate_renew_account_expiry_date(params) do
    start_date = Ecto.Date.cast!(params["effectivity_date"])
    end_date = Ecto.Date.cast!(params["expiry_date"])

    case Ecto.Date.compare(start_date, end_date) do
      :lt ->
        {:valid, end_date}
      :gt ->
        {:end_date_error, end_date}
      :eq ->
        {:end_date_error, end_date}
      _ ->
        {:end_date_error, end_date}
    end

  end


  def is_date?(date) do
    case Date.from_iso8601(date) do
      {:ok, _} -> true

      {:error, :invalid_format} -> false

      {:error, :invalid_date} -> false

    end
  end


  def check_cancellation_date(params, latest_account) do
    with true <- is_nil(latest_account.cancel_date),
         true <- is_nil(latest_account.suspend_date) do
      {:ok, params}

    else
      false ->
        {:cancellation_date_error, params}
    end
  end

end
