defmodule Innerpeace.Db.Base.AccountContextTest do
  use Innerpeace.Db.SchemaCase
  import Innerpeace.Db.Base.AccountContext
  alias Ecto.UUID
  alias Innerpeace.Db.Base.ContactContext
  alias Innerpeace.Db.Schemas.{
    Account,
    AccountGroupAddress,
    AccountGroupContact,
    AccountGroup,
    # AccountLog,
    AccountProduct,
    AccountProductBenefit,
    Bank,
    Contact,
    Fax,
    PaymentAccount,
    Phone,
    AccountComment
  }

  @invalid_attrs %{}

  test "list all accounts" do
    account =
      :account
      |> insert(step: "1")
      |> Repo.preload([:account_logs])
    assert list_accounts() == [Map.merge(account, %{account_group: nil})]
  end

  test "list all account_groups" do
    account_group = insert(:account_group)
    account =
      insert(:account,
             account_group: account_group,
             status: "Active",
             major_version: 1,
             minor_version: 0,
             build_version: 0)

    left = list_account_groups()
    right = [%{
      code: account_group.code, end_date: account.end_date, id: account_group.id,
      name: account_group.name, start_date: account.start_date, status: account.status,
      version: "#{account.major_version}.#{account.minor_version}.#{account.build_version}"
    }]

    assert left == right
  end

  test "list all industry" do
    industry = insert(:industry,  code: "101")
    assert list_industry() == [industry]
  end

  test "list all organization" do
    account = insert(:account, step: "1")
    organization = insert(:organization, name: "Organization 101", account: account)

    left =
      list_organization()
      |> Enum.at(0)
      |> Map.delete(:account)

    right = Map.delete(organization, :account)

    assert left == right
  end

  test "list all account products" do
    account = insert(:account, step: "1")
    product = insert(:product)
    account_product = insert(:account_product, account: account, product: product)

    left =
      account.id
      |> list_all_account_products()
      |> Enum.at(0)
      |> Map.drop([:product, :account, :member_products])

    right = Map.drop(account_product, [:account, :product, :member_products])

    assert left == right
  end

  test "List all approver" do
    account_group = insert(:account_group)
    account_group_approval = insert(:account_group_approval, account_group: account_group)

    left =
      account_group.id
      |> list_all_approver()
      |> Enum.at(0)
      |> Map.delete(:account_group)

    right =
      account_group_approval
      |> Map.delete(:account_group)

    assert left == right
  end

  test "preload_account_group" do
    account_group = insert(:account_group)
    account = insert(:account, account_group: account_group)

    right =
      account
      |> Map.delete(:account_group)

    assert Map.delete(account, :account_group) == right
  end

  test "get_account! returns the account with given id" do
    right =
      :account
      |> insert(step: "1")
      |> Repo.preload([:account_logs, :account_products])
      |> Map.delete(:account_group)
    left = right.id
           |> get_account!
           |> Map.delete(:account_group)
    assert left == right
  end

  test "get_account_group! returns the account_group with given id" do
    account_group = insert(:account_group)
    insert(:account, account_group: account_group)
    get_account_group =
      account_group
      |> Repo.preload([
          :account,
          :account_logs,
          :account_group_address,
          :contacts,
          :payment_account,
          :members,
          :industry,
          :bank,
          :account_group_contacts])

    assert get_account_group(account_group.id) == get_account_group
  end

  test "get_account_group_address! returns the account_group_address with given id" do
    account_group = insert(:account_group)
    insert(:account, account_group: account_group, step: "1")
    account_group_address =
      :account_group_address
      |> insert(type: "Company Address", account_group: account_group)
      |> Repo.preload([:account_group, :account_logs])
    left =
      account_group.id
      |> get_account_group_address!("Company Address")
      |> Map.delete(:account_group)
    assert left == Map.delete(account_group_address, :account_group)
  end

  test "get_all_account_group_address! returns all account_group_address" do
    account_group = insert(:account_group)
    insert(:account, step: "1", account_group: account_group)
    account_group_address = insert(:account_group_address, type: "Company Address", account_group: account_group)

    left =
      account_group.id
      |> get_all_account_group_address()
      |> Enum.at(0)
      |> Map.delete(:account_group)
    assert left == Map.delete(account_group_address, :account_group)
  end

  test "get_contact! returns the contact with given id" do
    contact =
      :contact
      |> insert()
      |> Repo.preload([:account_logs])
    left =
      contact.id
      |> ContactContext.get_contact!()
      |> Map.drop([:phones, :fax, :emails])
    right  = Map.drop(contact, [:phones, :fax, :emails])

    assert left == right
  end

  test "get_all_contacts returns the contact with given id" do
    account_group = insert(:account_group)
    contact = insert(:contact)
    insert(:account_group_contact, account_group: account_group, contact: contact)
    assert account_group.id |> get_all_contacts() |> Enum.at(0) |> Map.delete(:phones) == contact |> Map.delete(:phones)
  end

  test "get_account_with_account_group" do
    account_group = insert(:account_group)
    account =
      :account
      |> insert(account_group: account_group)
      |> Map.delete(:account_group)
    result =
      account.id
      |> get_account_with_account_group(account_group.id)
      |> Map.delete(:account_group)

    assert result == account
  end

  test "get_all_account_tin" do
    payment =
      :payment_account
      |> insert(account_tin: "123")
      |> Map.drop([:account_group, :updated_at, :inserted_at, :account_group_id, :id])

    result =
      get_all_account_tin()
      |> Enum.at(0)
      |> Map.drop([:account_group, :updated_at, :inserted_at, :account_group_id, :id])

    assert result == payment
  end

  test "get_account_payment returns the Payment Account with given id" do
    account_group =
      :account_group
      |> insert()
      |> Repo.preload([:account, :account_logs])
    account_payment =
      :payment_account
      |> insert(account_group: account_group)
      |> Repo.preload([:account_group, :account_logs])
    left = account_group.id
           |> get_account_payment!
           |> Map.delete(:account_group)
    assert left == Map.delete(account_payment, :account_group)
  end

  test "get_bank! returns the bank with given id" do
    account_group =
      :account_group
      |> insert()
      |> Repo.preload([:account, :account_logs])
    bank =
      :bank
      |> insert(account_group: account_group)
      |> Repo.preload([:account_group, :account_logs])
    left =
      account_group.id
      |> get_bank
      |> Map.delete(:account_group)
    assert left == Map.delete(bank, :account_group)
  end

  test "get_product! returns the product with given id" do
    product = insert(:product)
    left =
      product.id
      |> get_product
      |> Map.delete(:payor)
      |> Map.delete(:logs)
      |> Map.delete(:product_coverages)
      |> Map.delete(:product_condition_hierarchy_of_eligible_dependents)
      |> Map.delete(:account_products)
      |> Map.delete(:product_exclusions)
      |> Map.delete(:product_benefits)
    right =
      product
      |> Map.delete(:payor)
      |> Map.delete(:logs)
      |> Map.delete(:product_coverages)
      |> Map.delete(:product_condition_hierarchy_of_eligible_dependents)
      |> Map.delete(:account_products)
      |> Map.delete(:product_exclusions)
      |> Map.delete(:product_benefits)
    assert left == right
  end

  test "get_account_product! returns the account_product with given id" do
    account = insert(:account)
    product = insert(:product)
    account_product = insert(:account_product, account: account, product: product)

    left =
      account_product.id
      |> get_account_product!
      |> Map.drop([:account, :product])
    right =
      account_product
      |> Map.drop([:account, :product])

    assert left == right
  end

  test "get_all_account_product! returns the account_product with given id" do
    account = insert(:account)
    product = insert(:product)
    account_product = insert(:account_product, account: account, product: product, rank: 1)

    left =
      account.id
      |> get_all_account_product
      |> Enum.at(0)
      |> Map.drop([:account, :product])

    right =
      account_product
      |> Map.drop([:account, :product])

    assert left == right
  end

  test "get_product_benefit returns the account_product with given id" do
    product = insert(:product)
    benefit = insert(:benefit)
    product_benefit = insert(:product_benefit, product: product, benefit: benefit)

    left =
      product.id
      |> get_product_benefit!
      |> Enum.at(0)

    right = %{product_benefit_id: product_benefit.id}

    assert left == right
  end

  test "get_summary_account returns the account summary with given id" do
    account_group = insert(:account_group)
    account = insert(:account, account_group: account_group)
    insert(:payment_account, account_group: account_group)
    insert(:bank, account_group: account_group)
    insert(:account_group_address, type: "Company Address", account_group: account_group)
    contact = insert(:contact)
    insert(:account_group_contact, account_group: account_group, contact: contact)
    assert get_summary_account(account) == account_group |> Repo.preload([
      :payment_account,
      :bank,
      :account_hierarchy_of_eligible_dependents,
      :account_group_address,
      :industry,
      account_group_fulfillments: [fulfillment: [card_files: :file]],
      account_group_contacts: [contact: [:phones, :fax]],
      account_group_coverage_funds: :coverage
    ])
  end

  test "create_account_group with valid data creates a account" do
    industry = insert(:industry)
    insert(:account_group)
    params = %{
      name: "AccountTest2",
      type: "type",
      code: "Code1",
      segment: "Corporate",
      phone_no: "09210042020",
      email: "admin@example.com",
      industry_id: industry.id,
      original_effective_date: Ecto.Date.cast!("2017-08-01")
    }
    assert {:ok, %AccountGroup{} = account_group} = create_account_group(params)
    assert account_group.name == "AccountTest2"
  end

  test "create_account_group with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = create_account_group(@invalid_attrs)
  end

  test "create_account with valid data creates a account" do
    account_group = insert(:account_group)
    user = insert(:user)
    organization = insert(:organization, name: "Organization 101")
    industry = insert(:industry)
    params = %{
      name: "AccountTest2",
      type: "type",
      code: "Code1",
      start_date: Ecto.Date.cast!("2017-01-01"),
      end_date: Ecto.Date.cast!("2017-01-10"),
      segment: "Corporate",
      phone_no: "09210042020",
      email: "admin@example.com",
      industry_id: industry.id,
      organization_id: organization.id,
      account_group_id: account_group.id,
      created_by: user.id,
      updated_by: user.id,
      step: 1
    }
    assert {:ok, %Account{} = account} = create_account(params)
    assert account.start_date == Ecto.Date.cast!("2017-01-01")
  end

  test "create_account with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = create_account(@invalid_attrs)
  end

  test "create_address with valid data creates a account address" do
    account_group = insert(:account_group)
    insert(:account, account_group: account_group)
    params = %{
      line_1: "101",
      line_2: "Name",
      street: "street",
      type: "Company Address",
      account_group_id: account_group.id,
      postal_code: "4001",
      city: "city",
      province: "province",
      country: "country",
      region: "region"
    }
    assert {:ok, %AccountGroupAddress{} = account_group_address} = create_address(params)
    assert account_group_address.line_1 == "101"
  end

  test "create_address with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = create_address(@invalid_attrs)
  end

  test "create_contact with valid data creates a contact" do
    params = %{
      type: "Contact Person",
      last_name: "Raymond Navarro",
      designation: "Software Engineer",
      # type: "Company Address",
      email: "admin@example.com",
      ctc: "ctc",
      ctc_date_issued: "2017-01-01",
      ctc_place_issued: "Place",
      passport_no: "101",
      passport_date_issued: "2017-01-10",
      passport_place_issued: "Place"
    }
    assert {:ok, %Contact{} = contact} = create_contact(params)
    assert contact.type == "Contact Person"
  end

  test "create_contact with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = create_contact(@invalid_attrs)
  end

  test "create_renew with valid date creates new account" do
    user = insert(:user)
    account_group = insert(:account_group)
    params = %{
      account_group_id: account_group.id,
      created_by: user.id,
      updated_by: user.id,
      account_group: account_group,
      major_version: 2,
      minor_version: 0,
      build_version: 0,
      status: "For Activation",
      step: 6
    }

    assert {:ok, %Account{} = account} = create_renew(params)
    assert account.major_version == 2
  end

  test "create_renew with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = create_renew(@invalid_attrs)
  end

  test "create_account_contact with valid data creates a account_contact" do
    account_group = insert(:account_group)
    contact = insert(:contact)
    params = %{
      account_group_id: account_group.id,
      contact_id: contact.id
    }
    assert {:ok, %AccountGroupContact{} = account_contact} = create_account_contact(params)
    assert account_contact.account_group_id == account_group.id
    assert account_contact.contact_id == contact.id
  end

  test "create_account_contact with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = create_account_contact(@invalid_attrs)
  end

  test "create_contact_no with valid data creates contact number" do
    contact = insert(:contact)
    params = %{
      number: "09210042525",
      contact_id: contact.id,
      type: "mobile"
    }
    assert {:ok, %Phone{} = phone} = create_contact_no(params)
    assert phone.number == "09210042525"
  end

  test "create_contact_no with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = create_contact_no(@invalid_attrs)
  end

  test "create_fax with valid data creates fax" do
    contact = insert(:contact)
    params = %{
      number: "64464",
      contact_id: contact.id
    }
    assert {:ok, %Fax{} = fax} = create_fax(params)
    assert fax.number == "64464"
  end

  test "create_fax with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = create_fax(@invalid_attrs)
  end

  test "create_payment with valid data creates payment_account" do
    account_group = insert(:account_group)
    params = %{
      account_group_id: account_group.id,
      account_tin: "AccountTIN",
      vat_status: "20% VAT-able",
      p_sched_of_payment: "ANNUAL",
      d_sched_of_payment: "ANNUAL",
      previous_carrier: "carrier",
      attched_point: "attached",
      revolving_fund: "fund",
      threshold_limit: "limit"
    }
    assert {:ok, %PaymentAccount{} = payment} = create_payment(params)
    assert payment.account_tin == "AccountTIN"
  end

  test "create_payment with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = create_payment(@invalid_attrs)
  end

  test "create_bank_account with valid data creates bank account" do
    account_group = insert(:account_group)
    params = %{
      account_group_id: account_group.id,
      account_name: "Medilink Bank Account",
      account_no: "12345678"
    }
    assert {:ok, %Bank{} = bank} = create_bank_account(params)
    assert bank.account_name == "Medilink Bank Account"
  end

  test "create_bank_account with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = create_bank_account(@invalid_attrs)
  end

  test "create_account_product with valid data creates account product" do
    account = insert(:account)
    product = insert(:product)
    benefit = insert(:benefit)
    insert(:account_product, account: account, product: product, name: "AccountProduct")
    insert(:product_benefit, product: product, benefit: benefit)
    params = %{
      account_id: account.id,
      product_id: product.id,
      name: "AccountProduct",
      description: "test",
      limit_type: "test",
      limit_amount: 12,
      limit_applicability: "Share with family",
      type: "Gold",
      rank: 1
    }
    assert create_account_product(params) == :ok
  end

  test "create_account_product_benefit with valid data creates account product benefit" do
    account = insert(:account)
    benefit = insert(:benefit)
    product = insert(:product)
    account_product = insert(:account_product, account: account, product: product, name: "AccountProduct")
    product_benefit = insert(:product_benefit, product: product, benefit: benefit)
    insert(:account_product_benefit, account_product: account_product, product_benefit: product_benefit)
    params = %{
      account_product_id: account_product.id,
      product_benefit_id: product_benefit.id,
    }
    assert {:ok, %AccountProductBenefit{} = account_product_benefit} = create_account_product_benefit(params)
    assert account_product_benefit.account_product_id == account_product.id
    assert account_product_benefit.product_benefit_id == product_benefit.id
  end

  test "create_account_product_benefit with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = create_account_product_benefit(@invalid_attrs)
  end

  test "update_account with valid data updates the account" do
    account_group = insert(:account_group)
    account = insert(:account)
    user = insert(:user)
    organization = insert(:organization, name: "Organization 101")
    industry = insert(:industry)
    params = %{
      name: "AccountTest2",
      type: "type",
      code: "Code1",
      start_date: Ecto.Date.cast!("2017-01-01"),
      end_date: Ecto.Date.cast!("2017-01-10"),
      segment: "Corporate",
      phone_no: "09210042020",
      email: "admin@example.com",
      industry_id: industry.id,
      organization_id: organization.id,
      account_group_id: account_group.id,
      updated_by: user.id,
      step: 1
    }
    assert {:ok, %Account{} = account} = update_account(account, params)
    assert account.start_date == Ecto.Date.cast!("2017-01-01")
  end

  test "update_account with invalid data returns error changeset" do
    account =
      :account
      |> insert()
      |> Repo.preload([:account_logs, :account_products])
    assert {:error, %Ecto.Changeset{}} = update_account(account, @invalid_attrs)
    assert Map.delete(account, :account_group) == Map.delete(get_account!(account.id), :account_group)
  end

  test "update_account_group with valid data updates the account_group" do
    account_group = insert(:account_group)
    industry = insert(:industry)
    params = %{
      name: "AccountTest2",
      type: "type",
      code: "Code1",
      segment: "Corporate",
      phone_no: "09210042020",
      email: "admin@example.com",
      industry_id: industry.id,
      original_effective_date: Ecto.Date.cast!("2017-08-01")
    }
    assert {:ok, %AccountGroup{} = account_group} = update_account_group(account_group, params)
    assert account_group.name == "AccountTest2"
  end

  test "update_account_group with invalid data returns error changeset" do
    account_group = insert(:account_group)
    account =
      :account
      |> insert(account_group: account_group)
      |> Map.delete(:account_group)

    assert {:error, %Ecto.Changeset{}} = update_account_group(account_group, @invalid_attrs)
    assert account == account_group.id |> get_account_group!() |> Map.delete(:account_group)
  end

  test "update_account_step with valid data updates the account step" do
    account = insert(:account)
    params = %{
      step: 2,
      account_id: account.id
    }
    assert {:ok, %Account{} = account} = update_account_step(account, params)
    assert account.step == 2
  end

  test "update_account_group_address with valid data updates the account address" do
    account_group = insert(:account_group)
    insert(:account, account_group: account_group)
    account_group_address = insert(:account_group_address, account_group: account_group)
    params = %{
      line_1: "101",
      line_2: "Name",
      street: "street",
      type: "Company Address",
      postal_code: "4001",
      city: "city",
      province: "province",
      country: "country",
      region: "region"
    }
    assert {:ok, %AccountGroupAddress{} = ag_address} = update_account_group_address(account_group_address, params)
    assert ag_address.line_1 == "101"
  end

  test "update_account_group_address with invalid data returns error changeset" do
    account_group = insert(:account_group)
    insert(:account, account_group: account_group)
    account_group_address =
      :account_group_address
      |> insert(account_group: account_group, type: "Company Address")
      |> Repo.preload([:account_group, :account_logs])

    get_account_address =
      account_group.id
      |> get_account_group_address!("Company Address")
      |> Map.delete(:account_group)

    assert {:error, %Ecto.Changeset{}} = update_account_group_address(account_group_address, @invalid_attrs)
    assert Map.delete(account_group_address, :account_group) == get_account_address
  end

  test "update_account_contact with valid data updates the account contact" do
    insert(:account)
    contact = insert(:contact)
    params = %{
      type: "Contact Person",
      last_name: "Raymond Navarro",
      designation: "Software Engineer",
      # type: "Contact Person",
      email: "admin@example.com",
      ctc: "ctc",
      ctc_date_issued: "2017-01-01",
      ctc_place_issued: "Place",
      passport_no: "101",
      passport_date_issued: "2017-01-10",
      passport_place_issued: "Place"
    }
    assert {:ok, %Contact{} = contact} = update_account_contact(contact, params)
    assert contact.type == "Contact Person"
  end

  test "update_account_contact with invalid data returns error changeset" do
    insert(:account)
    contact =
      :contact
      |> insert()
      |> Repo.preload([:account_logs])
    left =
      contact.id
      |> ContactContext.get_contact!()
      |> Map.drop([:phones, :fax, :emails])
    right  = Map.drop(contact, [:phones, :fax, :emails])

    assert {:error, %Ecto.Changeset{}} = update_account_contact(contact, @invalid_attrs)
    assert left == right
  end

  test "update_payment with valid data updates the account payment" do
    account_group = insert(:account_group)
    payment_account = insert(:payment_account, account_group: account_group)
    params = %{
      account_group_id: account_group.id,
      account_tin: "AccountTIN",
      vat_status: "20% VAT-able",
      p_sched_of_payment: "ANNUAL",
      d_sched_of_payment: "ANNUAL",
      previous_carrier: "carrier",
      attched_point: "attached",
      revolving_fund: "fund",
      threshold_limit: "limit"
    }
    assert {:ok, %PaymentAccount{} = payment_account} = update_account_payment(payment_account, params)
    assert payment_account.account_tin == "AccountTIN"
  end

  test "update_account_payment with invalid data returns error changeset" do
    account_group =
      :account_group
      |> insert()
      |> Repo.preload([:account, :account_logs])
    payment_account =
      :payment_account
      |> insert(account_group: account_group)
      |> Repo.preload([:account_group, :account_logs])
    get_payment_account =
      account_group.id
      |> get_account_payment!()
      |> Map.delete(:account_group)
    assert {:error, %Ecto.Changeset{}} = update_account_payment(payment_account, @invalid_attrs)
    assert Map.delete(payment_account, :account_group) == get_payment_account
  end

  test "update_bank_account with valid data updates the bank" do
    account_group = insert(:account_group)
    bank = insert(:bank, account_group: account_group)
    params = %{
      account_group_id: account_group.id,
      account_name: "Medilink Bank Account",
      account_no: "12345678"
    }
    assert {:ok, %Bank{} = bank} = update_bank_account(bank, params, account_group.id)
    assert bank.account_name == "Medilink Bank Account"
  end

  test "update_bank_account with nil bank data updates the bank" do
    account_group = insert(:account_group)
    insert(:bank, account_group: account_group)
    params = %{
      "account_name" => "Medilink Bank Account",
      "account_no" => "12345678"
    }
    assert {:ok, %Bank{} = bank} = update_bank_account(nil, params, account_group.id)
    assert bank.account_name == "Medilink Bank Account"
  end

#  test "update_bank_account with invalid data returns error changeset" do
#    account_group = insert(:account_group) |> Repo.preload([:account, :account_logs])
#    bank = insert(:bank, account_group: account_group) |> Repo.preload([:account_group, :account_logs])
#
#    assert {:error, %Ecto.Changeset{}} = update_bank_account(bank, @invalid_attrs, account_group.id)
#    assert Map.delete(bank, :account_group) == get_bank(account_group.id) |> Map.delete(:account_group)
#  end

  test "update_account_product with data updates the product" do
    account = insert(:account)
    product = insert(:product)
    account_product = insert(:account_product, account: account, product: product, rank: 1)
    params = %{
      name: "AccountProduct",
      description: "test",
      limit_type: "test",
      limit_amount: 12,
      limit_applicability: "Share with family",
      type: "Gold",
      rank: 1
    }

    assert {:ok, %AccountProduct{} = account_product} = update_account_product(account_product, params)
    assert account_product.name == "AccountProduct"
  end

  test "update_account_product with invalid data returns error changeset" do
    account = insert(:account)
    product = insert(:product)
    account_product = insert(:account_product, account: account, product: product)

    assert {:error, %Ecto.Changeset{}} = update_account_product(account_product, @invalid_attrs)
  end

  test "update_account_version with valid data updates the version" do
    account = insert(:account)
    params = %{
      major_version: 1,
      minor_version: 0,
      build_version: 0
    }

    assert {:ok, %Account{} = account} = update_account_version(account, params)
    assert account.major_version == 1
  end

  test "delete_account deletes the account" do
    account_group = insert(:account_group)
    insert(:account, account_group: account_group)
    insert(:payment_account, account_group: account_group)
    insert(:bank, account_group: account_group)
    insert(:account_group_address, type: "Company Address", account_group: account_group)
    contact = insert(:contact)
    insert(:account_group_contact, account_group: account_group, contact: contact)
    delete_account(account_group.id)
    get_account_group(account_group.id)
    # assert nil == account_group
  end

  test "delete_contact deletes the contact" do
    account_group = insert(:account_group)
    contact = insert(:contact)
    insert(:account_group_contact, account_group: account_group, contact: contact)
    assert {1, _} = delete_contact(account_group.id, contact.id)
    assert_raise Ecto.NoResultsError, fn -> ContactContext.get_contact!(account_group.id) end
  end

  test "delete_account_product! deletes account product" do
    account = insert(:account)
    product = insert(:product)
    account_product = insert(:account_product, account: account, product: product)

    assert {:ok, _account_product} =  delete_account_product!(account_product)
    #assert {:ok, _} = delete_account_product!(account_product)
    #assert_raise Ecto.NoResultsError, fn -> get_account_product!(account_product.id) end
  end

  test "delete_all_account_product! deletes all account product" do
    account = insert(:account)
    product = insert(:product)
    insert(:account_product, account: account, product: product)
    #Jassert {1, nil} = delete_all_account_product(account.id)
    # assert_raise Ecto.NoResultsError, fn -> get_account_product!(account_product.id) end
  end

  test "change_account/1 returns a account changeset" do
    account = insert(:account)
    assert %Ecto.Changeset{} = change_account(account)
  end

  test "change_account_group/1 returns a account_group changeset" do
    account_group = insert(:account_group)
    assert %Ecto.Changeset{} = change_account_group(account_group)
  end

  test "update_account_expiry with valid data updates the account expiry date" do
    account = insert(:account, status: "Active")
    params = %{
      end_date: Ecto.Date.cast!("2017-01-10")
    }
    assert {:ok, %Account{} = account} = update_account_expiry(account, params)
    assert account.end_date == Ecto.Date.cast!("2017-01-10")
  end

  test "create account log for General Tab with valid changeset" do
    account_group =
      :account_group
      |> insert()
      |> Repo.preload([:account, :account_logs, :account_group_address, :contacts, :payment_account])
    organization = insert(:organization, name: "Organization 101")
    industry = insert(:industry)
    user = insert(:user, %{username: "admin", email: "admin@.admin.com"})
        params = %{
          name: "AccountTest",
          type: "type",
          code: "Code",
          start_date: Ecto.Date.cast!("2017-01-01"),
          end_date: Ecto.Date.cast!("2017-01-10"),
          segment: "Corporate",
          phone_no: "09210042020",
          email: "admin@example.com",
          industry_id: industry.id,
          original_effective_date: Ecto.Date.cast!("2017-08-01"),
          organization_id: organization.id,
          account_group_id: account_group.id,
          updated_by: user.id,
          step: 1
        }
    changeset = AccountGroup.changeset(account_group, params)
    tab = "General"
    account_log = create_account_log(user, changeset, tab)
    assert {:ok , %AccountGroup{}} = update_account_group(account_group, params)
    assert account_log.user_id == user.id
  end

  test "create account log for Address Tab with valid changeset" do
    account_group =
      :account_group
      |> insert()
      |> Repo.preload([:account, :account_logs, :account_group_address, :contacts, :payment_account])
    account_group_address =
      :account_group_address
      |> insert(type: "Company Address", account_group: account_group)
      |> Repo.preload([:account_group, :account_logs])
    user = insert(:user, %{username: "admin", email: "admin@.admin.com"})
    params = %{
      line_1: "101",
      line_2: "Name",
      building_name: "Name",
      unit_no: "101",
      street: "street",
      type: "Company Address",
      account_group_id: account_group.id,
      postal_code: "4001",
      city: "city",
      province: "province",
      country: "country",
      region: "region"
    }
    changeset = AccountGroupAddress.changeset(account_group_address, params)
    tab = "Address"
    account_log = create_account_group_log(user, changeset, tab)
    assert {:ok , %AccountGroupAddress{}} = update_account_group_address(account_group_address, params)
    assert account_log.user_id == user.id
  end

  test "create account log for Financial Tab with Check as Mode of Payment and has a valid changeset" do
    account_group =
      :account_group
      |> insert()
      |> Repo.preload([:account, :account_logs, :account_group_address, :contacts, :payment_account])
    account_payment =
      :payment_account
      |> insert(account_group: account_group)
      |> Repo.preload([:account_group, :account_logs])
    user = insert(:user, %{username: "admin", email: "admin@.admin.com"})
    params = %{
      account_group_id: account_group.id,
      account_tin: "AccountTIN",
      vat_status: "20% VAT-able",
      p_sched_of_payment: "ANNUAL",
      d_sched_of_payment: "ANNUAL",
      previous_carrier: "carrier",
      attched_point: "attached",
      revolving_fund: "fund",
      threshold_limit: "limit",
    }
    changeset = PaymentAccount.changeset_account(account_payment, params)
    tab = "Finanical"
    account_log = create_account_group_log(user, changeset, tab)
    assert {:ok , %PaymentAccount{}} = update_account_payment(account_payment, params)
    assert account_log.user_id == user.id
  end

  test "create account log for Financial Tab with Electronic Debit as Mode of Payment and has a valid changeset" do
    account_group =
      :account_group
      |> insert()
      |> Repo.preload([:account, :account_logs, :account_group_address, :contacts, :payment_account])
    bank = insert(:bank, account_group: account_group)
    user = insert(:user, %{username: "admin", email: "admin@.admin.com"})
    params = %{
      account_group_id: account_group.id,
      account_name: "Medilink Bank Account",
      account_no: "12345678"
    }
    changeset = Bank.changeset(bank, params)
    tab = "Finanical"
    account_log = create_account_group_log(user, changeset, tab)
    assert {:ok , %Bank{}} = update_bank_account(bank, params, account_group.id)
    assert account_log.user_id == user.id
  end

  test "create_comment* with valid data creates a comment" do
    account = insert(:account)
    user = insert(:user, username: "name")

    params = %{
      comment: "COMMENT101",
      user_id: user.id,
      account_id: account.id
    }
    assert {:ok, %AccountComment{}} = create_comment(params)
  end

  test "get_all_comments" do
    account = insert(:account)
    user = insert(:user)
    account_comment =
      :account_comment
      |> insert(comment: "Testing", account_id: account.id, user_id: user.id)
      |> Repo.preload([:account, :user])

    left =
      account.id
      |> get_all_comments
    right =
      account_comment
      |> List.wrap

    assert left == right
  end

  test "get_comment_count* test" do
    account = insert(:account)
    user = insert(:user)

    :account_comment
    |> insert(comment: "Testing", account_id: account.id, user_id: user.id)
    |> Repo.preload([:account, :user])

    assert get_comment_count(account.id) == 1
  end

  test "change_account_comment * returns a account_comment changeset" do
    account = insert(:account)
    user = insert(:user)
    account_comment =
      :account_comment
      |> insert(comment: "Testing", account_id: account.id, user_id: user.id)
      |> Repo.preload([:account, :user])
    assert %Ecto.Changeset{} = change_account_comment(account_comment)
  end

  test "insert_or_update_account * validates account" do
    account = insert(:account)
    account_group = insert(:account_group)
    user = insert(:user)
    get_account = get_account_by_account_group(account_group.id)

    if is_nil(get_account) do
      params = %{
        start_date: Ecto.Date.cast!("2017-08-01"),
        end_date: Ecto.Date.cast!("2018-08-01"),
        status: "Active",
        account_group_id: account_group.id,
        major_version: 1,
        minor_version: 0,
        build_version: 0,
        updated_by: user.id,
        step: 2
      }
      assert {:ok, %Account{} = account} = create_an_account(params)
      assert account.account_group_id == account_group.id
    else
      params = %{
        start_date: Ecto.Date.cast!("2017-09-01"),
        end_date: Ecto.Date.cast!("2018-09-01"),
        account_group_id: account_group.id,
        updated_by: user.id,
        step: 5
      }
      assert {:ok, %Account{} = account} = update_an_accounts(account.id, params)
      assert account.end_date == Ecto.Date.cast!("2018-09-01")

    end
  end

  test "get_account_by_account_group * returns the account with given account group id" do
    account = insert(:account)
    account_group = insert(:account_group)
    assert get_account_by_account_group(account_group.id) == account.account_group_id
  end

  test "get_account * returns the account with given id" do
    account = insert(:account)
    assert get_account(account.id) == account
    |> Repo.preload([account_products:
                     [product:
                      [product_benefits:
                       [benefit: [
                         :created_by,
                         :updated_by,
                         :benefit_limits,
                         benefit_procedures: :procedure,
                         benefit_coverages: :coverage]
                       ],
                      product_coverages: [
                        :coverage,
                        product_coverage_facilities: [facility: [:category, :type]]
                      ]
                      ]
                     ]
    ])
  end

  test "create_an_account * with valid data creates an account" do
    account_group = insert(:account_group)
    user = insert(:user)
    insert(:account)
    params = %{
      start_date: Ecto.Date.cast!("2017-08-01"),
      end_date: Ecto.Date.cast!("2018-08-01"),
      status: "Active",
      account_group_id: account_group.id,
      major_version: 1,
      minor_version: 0,
      build_version: 0,
      updated_by: user.id,
      step: 2
    }
    assert {:ok, %Account{} = account} = create_an_account(params)
    assert account.account_group_id == account_group.id
  end

  test "create_an_account with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = create_an_account(@invalid_attrs)
  end

  test "update_an_accounts with valid data updates the account expiry date" do
    account = insert(:account)
    account_group = insert(:account_group)
    user = insert(:user)
    params = %{
      start_date: Ecto.Date.cast!("2017-09-01"),
      end_date: Ecto.Date.cast!("2018-09-01"),
      account_group_id: account_group.id,
      updated_by: user.id,
      step: 5
    }
    assert {:ok, %Account{} = account} = update_an_accounts(account.id, params)
    assert account.end_date == Ecto.Date.cast!("2018-09-01")
  end

  test "update_an_accounts with invalid data returns error changeset" do
    account =
      :account
      |> insert()
      |> Repo.preload([:account_logs, :account_products])

    assert {:error, %Ecto.Changeset{}} = update_an_accounts(account.id, @invalid_attrs)
    assert Map.delete(account, :account_group) == Map.delete(get_account!(account.id), :account_group)
  end

   test "suspend_account* with valid data updates the account" do
    account = insert(:account)
    params = %{
      status: "Suspended",
      suspend_date: "2017-08-09",
      suspend_remarks: "Remarks",
      suspend_reason: "Test"

    }
    assert {:ok, %Account{}} = suspend_account(account, params)
  end

  test "reactivate_account* with valid data updates the account" do
    account = insert(:account)
    params = %{
      status: "Active",
      reactivate_date: "2017-08-09",
      reactivate_remarks: "Remarks"
    }
    assert {:ok, %Account{}} = reactivate_account(account, params)
  end

  test "activate_status" do
    account = insert(:account)

    assert {:ok, %Account{} = account} = activate_status(account, %{status: "For Renewal"})
    assert account.status == "For Renewal"
  end

  test "activate_status with invalid data" do
    account = insert(:account)
    assert {:error, %Ecto.Changeset{}} = activate_status(account, @invalid_attrs)
  end

  test "renewal_cancel" do
    account = insert(:account)

    assert {:ok, %Account{} = account} = renewal_cancel(account, %{status: "Renewal Cancelled"})
    assert account.status == "Renewal Cancelled"
  end

  test "renewal_cancel with invalid data" do
    account = insert(:account)
    assert {:error, %Ecto.Changeset{}} = renewal_cancel(account, @invalid_attrs)
  end

  test "get_latest_account" do
    account_group = insert(:account_group)
    account =
      :account
      |> insert(status: "Active", account_group: account_group)
      |> Map.delete(:account_group)
    result =
      account_group.id
      |> get_latest_account()
      |> Map.delete(:account_group)

    assert result == account
  end

  test "update_all_active with valid effectivity date" do
    account_group = insert(:account_group)
    account = insert(:account, start_date: "2017-01-01", status: "Lapsed", account_group: account_group)
    result = update_all_active(account)

    refute is_nil(result)
  end

  test "update_all_active with invalid effectivity date" do
    account = insert(:account, start_date: "2999-11-01", status: "Lapsed")
    result = update_all_active(account)

    assert is_nil(result)
  end

  test "clone_account_product" do
    account_new = insert(:account)
    account = insert(:account)
    product = insert(:product)
    benefit = insert(:benefit)
    account_product = insert(:account_product, account: account, product: product, name: "AccountProduct", rank: 1)
    product_benefit = insert(:product_benefit, product: product, benefit: benefit)
    insert(:account_product_benefit, account_product: account_product, product_benefit: product_benefit)

    assert clone_account_product(account, account_new) == :ok
    cloned_product =
      account_new
      |> Ecto.assoc(:account_products)
      |> Repo.all()
      |> Enum.at(0)

    assert product.name == cloned_product.name
  end

  test "expired_account with expired date" do
    account_group = insert(:account_group, code: "404")
    insert(:member, account_code: "404", status: "Active")
    insert(:account, status: "Active", end_date: "2017-08-01", account_group: account_group)

    result =
      account_group.id
      |> expired_account()
      |> Enum.at(0)

    refute is_nil(result)
  end

  test "expired_account with not expired date" do
    account_group = insert(:account_group)
    insert(:account, status: "Active", end_date: "2050-01-01", account_group: account_group)

    result =
      account_group.id
      |> expired_account()
      |> Enum.at(0)

    assert is_nil(result)
  end

  test "active_account with valid date" do
    account_group = insert(:account_group)
    insert(:account, status: "Active", start_date: "2017-08-08", account_group: account_group)
    insert(:account, status: "Active", start_date: "2017-08-08")
    insert(:account, status: "Pending", start_date: "2017-08-08", account_group: account_group)

    result =
      account_group.id
      |> active_account()
      |> Enum.at(0)

    refute is_nil(result)
  end

  test "active_account with invalid date and status" do
    account_group = insert(:account_group)
    insert(:account, status: "Active")
    insert(:account, status: "Active")
    insert(:account, status: "Pending", start_date: "2050-08-08", account_group: account_group)
    insert(:account, status: "Lapsed", start_date: "2017-08-08", account_group: account_group)

    result =
      account_group.id
      |> active_account()
      |> Enum.at(0)

    assert is_nil(result)
  end

  test "check_contact_type with valid contact type" do
    account_group = insert(:account_group)
    contact = insert(:contact, type: "Corp Signatory")
    contact2 = insert(:contact, type: "Contact Person")
    insert(:account_group_contact, account_group: account_group, contact: contact)
    insert(:account_group_contact, account_group: account_group, contact: contact2)

    assert check_contact_type(account_group.id, "Corp Signatory") > 0
    assert check_contact_type(account_group.id, "Contact Person") > 0
  end

  test "check_contact_type with invalid contact type" do
    account_group = insert(:account_group)

    assert check_contact_type(account_group.id, "Corp Signatory") == 0
    assert check_contact_type(account_group.id, "Contact Person") == 0
  end

  test "get_active_account with valid account group id" do
    account_group = insert(:account_group)
    account = insert(:account, account_group: account_group, status: "Active")

    result = get_active_account(account.account_group_id)

    assert account.id == result.id
  end

  test "get_active_account with invalid account group id" do
    account_group = insert(:account_group)
    insert(:account, account_group: account_group, status: "Active")
    {_, id} = UUID.load(UUID.bingenerate())

    result = get_active_account(id)

    assert result == nil
  end

  test "get_for_renewal_account_version with valid account_group group id" do
    account_group = insert(:account_group)
    account = insert(:account, account_group: account_group, status: "For Renewal")

    result = get_for_renewal_account_version(account.account_group_id)

    assert account.id == result.id
  end

  test "get_for_renewal_account_version with invalid account group id" do
    account_group = insert(:account_group)
    insert(:account, account_group: account_group, status: "For Renewal")
    {_, id} = UUID.load(UUID.bingenerate())

    result = get_for_renewal_account_version(id)

    assert result == nil
  end

  test "download_accounts with valid data" do
    industry = insert(:industry)
    account_group = insert(:account_group, industry: industry)
    user = insert(:user)
    account =
      insert(:account,
             account_group: account_group,
             status: "Active",
             created_by: user.id,
             major_version: 1,
             minor_version: 0,
             build_version: 0)
    payment_account =
      insert(:payment_account, account_group: account_group, funding_arrangement: "ASO")
    cluster = insert(:cluster, industry: industry, code: "cl01", name: "cluster 01")
    insert(:account_group_cluster, account_group: account_group, cluster: cluster)
    codes = %{"params" => [account_group.code]}

    left = download_accounts(codes)
    right = [%{
      cluster_code: cluster.code, cluster_name: cluster.name, code: account_group.code,
      created_by: user.username, date_created: account.inserted_at, end_date: account.end_date,
      funding: payment_account.funding_arrangement, industry: industry.code, name: account_group.name,
      segment: account_group.segment, start_date: account.start_date, status: account.status,
      version: "#{account.major_version}.#{account.minor_version}.#{account.build_version}"}]

    assert left == right
  end

  test "Reactivate Account with valid date" do
    account_group = insert(:account_group)
    insert(:account, status: "Suspended", reactivate_date: "2017-08-19")
    insert(:account, status: "Suspended", reactivate_date: "2017-08-19", account_group: account_group)

    refute account_group.id |> reactivation_account() |> Enum.at(0) |> is_nil()
  end

  test "Reactivate Account with invalid date" do
    account_group = insert(:account_group)
    insert(:account, status: "Suspended", reactivate_date: "2100-08-19", account_group: account_group)

    assert account_group.id |> reactivation_account() |> Enum.at(0) |> is_nil()
  end

  test "Reactivate Account with invalid status" do
    account_group = insert(:account_group)
    insert(:account, status: "Active", reactivate_date: "2100-08-19", account_group: account_group)

    assert Enum.empty?(reactivation_account(account_group.id))
  end

  test "Suspend Account with valid date" do
    account_group = insert(:account_group, code: "404")
    insert(:member, account_code: "404", status: "Active")
    insert(:account, status: "Active", suspend_date: "2000-09-20", account_group: account_group)

    refute account_group.id |> suspension_account() |> Enum.at(0) |> is_nil()
  end

  test "Suspend Account with invalid date" do
    account_group = insert(:account_group)
    insert(:account, status: "Active", suspend_date: "2100-09-20", account_group: account_group)

    assert account_group.id |> suspension_account() |> Enum.at(0) |> is_nil()
  end

  test "Suspend Account with non-active status" do
    account_group = insert(:account_group)
    insert(:account, status: "For Renewal", suspend_date: "2000-09-20", account_group: account_group)

    assert Enum.empty?(suspension_account(account_group.id))
  end

  test "Cancel Account with valid date" do
    account_group = insert(:account_group, code: "404")
    insert(:member, account_code: "404", status: "Active")
    insert(:account, status: "Active", cancel_date: "2000-09-20", account_group: account_group)
    insert(:account, status: "Suspended", cancel_date: "2000-09-20", account_group: account_group)
    #insert(:account, status: "Active", account_group: account_group)

    refute account_group.id |> cancellation_account() |> Enum.at(0) |> is_nil()
  end

  test "Cancel Account with invalid date" do
    account_group = insert(:account_group)
    insert(:account, status: "Active", account_group: account_group)
    insert(:account, status: "Suspended", account_group: account_group)
    insert(:account, status: "Suspended", cancel_date: "2100-09-20", account_group: account_group)

    assert account_group.id |> cancellation_account() |> Enum.at(0) |> is_nil()
  end

  test "Cancel Account with status not Active nor Suspended" do
    account_group = insert(:account_group)
    insert(:account, status: "For Renewal", account_group: account_group)
    insert(:account, status: "Pending", account_group: account_group)
    insert(:account, status: "Draft", account_group: account_group)
    insert(:account, status: "For Activation", cancel_date: "2100-09-20", account_group: account_group)

    assert Enum.empty?(cancellation_account(account_group.id))
  end

  test "retract suspension date" do
    account_group = insert(:account_group)
    account = insert(:account, suspend_date: "2017-10-16", account_group: account_group)

    assert {:ok, account} = retract_movement("Suspension", account.id)
    assert is_nil(account.suspend_date)
  end

  test "retract cancellation date" do
    account_group = insert(:account_group)
    account = insert(:account, cancel_date: "2017-10-16", account_group: account_group)

    assert {:ok, account} = retract_movement("Cancellation", account.id)
    assert is_nil(account.cancel_date)
  end

  test "retract reactivation date" do
    account_group = insert(:account_group)
    account = insert(:account, reactivate_date: "2017-10-16", account_group: account_group)

    assert {:ok, account} = retract_movement("Reactivation", account.id)
    assert is_nil(account.reactivate_date)
  end

  test "retract movement with invalid attrs" do
    account_group = insert(:account_group)
    account = insert(:account, reactivate_date: "2017-10-16", account_group: account_group)

    assert {:error, _error} = retract_movement("Active", account.id)
    refute is_nil(account.reactivate_date)
  end

  test "update_product_tier/2, updates rank of an account product with valid rank" do
    account_product = insert(:account_product)

    {_ok, ap} = update_product_tier(account_product.id, "1")

    assert ap.rank == 1
  end

  test "update_product_tier/2, catch error with invalid rank value" do
    account_product = insert(:account_product)
    {:error, changeset} = update_product_tier(account_product.id, "")

    assert changeset.errors == [rank: {"can't be blank", [validation: :required]}]
    assert changeset.valid? == false

  end

  test "update_product_tier/2, catch error with invalid id format" do
    insert(:account_product)
    {:error, message} = update_product_tier("67e2f722-6e15-4b84-81cb-3d7659c02ada5", "1")

    assert message == "Invalid UUID"
  end

  test "update_product_tier/2, catch error with no account product" do
    insert(:account_product)
    {:error, message} = update_product_tier("67e2f722-6e15-4b84-81cb-3d7659c02ada", "1")

    assert message == "No Product Tier Found"
  end

  test "check_last_ap_rank/1, gets the last account product rank" do
    account = insert(:account)

    rank = check_last_ap_rank(account.id)
    assert rank == 1
  end

  test "clear_account_hierarchy/1, clears hoed record of an account" do
    account_group = insert(:account_group)
    account = insert(:account, account_group_id: account_group.id)
    clear_account_hierarchy(account.id)
  end

  test "insert_account_hierarchy/4, inserts a HOED record with valid data" do
    account_group = insert(:account_group)
    {:ok, result} = insert_account_hierarchy(account_group.id, "Married Employee", "Spouse", 1)
    assert account_group.id == result.account_group_id
  end

  test "insert_account_hierarchy/4, inserts a HOED record with invalid data" do
    account = insert(:account)
    {result, _record} = insert_account_hierarchy(account.id, "Married Employee", "Spouse", "")
    assert result == :error
  end

  test "update_account_step/2, updates account step with valid data" do
    account = insert(:account)
    {_result, record} = update_account_step(account.id, 5)

    assert record.step == 5
  end

  test "insert_enrollment_period" do
    account_group = insert(:account_group)
    params = %{
      "pep" => 1,
      "dep" => 2,
      "pep_dom" => "day",
      "dep_dom" => "month"
    }
    {status, account_group} = insert_enrollment_period(account_group.id, params)

    assert status == :ok
    assert account_group.principal_enrollment_period == 1
    assert account_group.dependent_enrollment_period == 2
    assert account_group.pep_day_or_month == "day"
    assert account_group.dep_day_or_month == "month"
  end
end
