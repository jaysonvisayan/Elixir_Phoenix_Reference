defmodule Innerpeace.PayorLink.Web.AccountControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper

  @create_attrs %{
    name: "AccountName",
    type: "Corporate",
    code: "AccountCode",
    start_date: Ecto.Date.cast!("2017-01-01"),
    end_date: Ecto.Date.cast!("2017-01-10"),
    segment: "Corporate",
    phone_no: "09210042020",
    email: "admin@example.com"
  }

  setup do
    conn = build_conn()
    account_group = insert(:account_group)
    account = insert(
      :account,
      account_group: account_group,
      step: 1,
      major_version: 1,
      minor_version: 0,
      build_version: 0)
    industry = insert(:industry, code: "101")
    # user = insert(:user, is_admin: true)
    user = fixture(:user_permission, %{keyword: "manage_accounts", module: "Accounts"})
    conn = authenticated(conn, user)
    {:ok, %{conn: conn, user: user, account: account, industry: industry, account_group: account_group}}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, account_path(conn, :index)
    assert html_response(conn, 200) =~ "Account"
  end

  test "renders form for new accounts", %{conn: conn} do
    conn = get conn, account_path(conn, :new)
    assert html_response(conn, 200) =~ "Add Account"
  end

  test "creates account and redirects to show when data is valid", %{conn: conn, industry: industry} do
    organization = insert(:organization)
    conn = post conn, account_path(conn, :create),
      account: Map.merge(@create_attrs, %{industry_id: industry.id, organization_id: organization.id})

    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == "/accounts/#{id}/setup?step=2"
  end

  test "does not create account and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, account_path(conn, :create), account: %{start_date: "2017-01-10", name: "name", code: "101", segment: "corporate", industry_id: Ecto.UUID.generate()}
    assert html_response(conn, 200) =~ "Add Account"
  end

  test "renders form for editing chosen account", %{conn: conn, account: account} do
    conn = get conn, account_path(conn, :edit, account)
    version = Enum.join([
      account.major_version,
      account.minor_version,
      account.build_version
    ], ".")
    assert html_response(conn, 200) =~ "Edit  v#{version}"
  end

  test "updates chosen general and redirects when data is valid", %{conn: conn, account: account, industry: industry, user: user} do
    organization = insert(:organization)
   conn = put conn, account_path(conn, :update_setup, account, step: 1), account: %{
      name: "AccountTest2",
      type: "type",
      code: "Code1",
      start_date: Ecto.Date.cast!("2017-01-01"),
      end_date: Ecto.Date.cast!("2017-01-10"),
      segment: "Corporate",
      phone_no: "09210042020",
      email: "admin@example.com",
      industry_id: industry.id,
      original_effective_date: Ecto.Date.cast!("2017-01-10"),
      organization_id: organization.id,
      created_by: user.id,
      updated_by: user.id,
      step: 2,
    }
    assert redirected_to(conn) == "/accounts/#{account.id}/setup?step=2"
  end

  test "does not update chosen general and renders errors when data is invalid", %{conn: conn, account: account} do
    conn = put conn, account_path(conn, :update_setup, account, step: 1), account: %{start_date: "2017-01-01", industry_id: Ecto.UUID.generate()}
    version = Enum.join([
      account.major_version,
      account.minor_version,
      account.build_version
    ], ".")
    assert html_response(conn, 200) =~ "Edit  v#{version}"
  end

  test "deletes chosen account", %{conn: conn, account_group: account_group} do
    conn = delete conn, account_path(conn, :delete, account_group)
    assert redirected_to(conn) == account_path(conn, :index)
    # conn = get conn, account_path(conn, :show, account, active: "profile")
    # conn.status == 404
  end

  test "renders form for new address", %{conn: conn, account: account} do
    conn = get conn, account_path(conn, :setup, account.id, step: 2)
    assert html_response(conn, 200) =~ "Address 1"
    assert html_response(conn, 200) =~ "Address 2"
    assert html_response(conn, 200) =~ "City"
    assert html_response(conn, 200) =~ "Province"
  end

  test "creates address and redirects when data is valid", %{conn: conn, account: account, account_group: account_group} do
    conn =
      post conn, account_path(conn, :create_address, account.id, step: 2, account_group: account_group.id), account: %{
      line_1: "101",
      line_2: "Name",
      type: "Company Address",
      account_group_id: account_group.id,
      postal_code: "4001",
      city: "city",
      province: "province",
      country: "country",
      region: "region",
      line_1_v2: "102",
      line_2_v2: "Name",
      postal_code_v2: "4001",
      city_v2: "city",
      province_v2: "province",
      country_v2: "country",
      region_v2: "region"
    }

    assert redirected_to(conn) == "/accounts/#{account.id}/setup?step=3"
  end

  test "does not create address and renders errors when data is invalid", %{conn: conn, account: account, account_group: account_group} do
    conn = post conn, account_path(conn, :create_address, account.id, account_group: account_group.id), account: %{}
    assert html_response(conn, 200) =~ "Add Account"
  end

  test "renders form for edit address", %{conn: conn, account: account} do
    conn = get conn, account_path(conn, :setup, account.id, step: 2)
    assert html_response(conn, 200) =~ "Address 1"
    assert html_response(conn, 200) =~ "Address 2"
    assert html_response(conn, 200) =~ "City"
    assert html_response(conn, 200) =~ "Province"
  end

  test "updates chosen address and redirects when data is valid", %{conn: conn, account: account, account_group: account_group} do
    insert(:account_group_address, account_group: account_group, type: "Account Address")
    conn = put conn, account_path(conn, :update_setup, account, step: 2), account: %{
      line_1: "101",
      line_2: "Name",
      type: "Account Address",
      district: "district",
      postal_code: "4001",
      city: "city",
      province: "province",
      country: "country",
      region: "region",
      line_1_v2: "102",
      line_2_v2: "Name",
      postal_code_v2: "4001",
      city_v2: "city",
      province_v2: "province",
      country_v2: "country",
      region_v2: "region"
    }
    assert redirected_to(conn) == "/accounts/#{account.id}/setup?step=3"
  end

  test "does not update chosen address and renders errors when data is invalid", %{conn: conn, account: account, account_group: account_group} do
    insert(:account_group_address, account_group: account_group, type: "Account Address")
    conn = put conn, account_path(conn, :update_setup, account, step: 2), account: %{}
    version = Enum.join([
      account.major_version,
      account.minor_version,
      account.build_version
    ], ".")
    assert html_response(conn, 200) =~ "Edit  v#{version}"
  end

  test "renders form for new contact", %{conn: conn, account: account} do
    conn = get conn, account_path(conn, :setup, account.id, step: 3)
    assert html_response(conn, 200) =~ "Designation"
  end

  test "creates contact and redirects when data is valid", %{conn: conn, account: account, account_group: account_group} do
    conn = post conn, account_path(conn, :create_contact, account_group.id), account: %{
      account_id: account.id,
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
      passport_place_issued: "Place",
      mobile: ["0921", "50000", "0915", "12345"],
      telephone: ["6363", "6364"],
      fax: ["64", "12345"]
    }

    assert redirected_to(conn) == "/accounts/#{account.id}/setup?step=3"
  end

  test "does not create contact and renders errors when data is invalid", %{conn: conn, account: account, account_group: account_group} do
    conn = post conn, account_path(conn, :create_contact, account_group.id), account: %{account_id: account.id}
    assert html_response(conn, 200) =~ "Add Account"
  end

   test "updates chosen contact and redirects when data is valid", %{conn: conn, account: account, account_group: account_group} do
     contact = insert(:contact, last_name: "Navarro")
     insert(:account_group_contact, account_group: account_group, contact: contact)
     conn = put conn, account_path(conn, :update_setup, account, step: 3), account: %{
       account_id: account.id,
       type: "Contact Person",
       last_name: "Shane Dela Rosa",
       designation: "Software Engineer",
       # type: "Company Address",
       contact_id: contact.id,
       email: "admin@example.com",
       ctc: "ctc",
       ctc_date_issued: "2017-01-01",
       ctc_place_issued: "Place",
       passport_no: "101",
       passport_date_issued: "2017-01-10",
       passport_place_issued: "Place",
       mobile: ["09210052020", "09210050000"],
       telephone: ["6363", "6364"],
       fax: ["64", "12345"]
     }

     assert redirected_to(conn) == "/accounts/#{account.id}/setup?step=3"
   end

  test "does not update chosen contact and renders errors when data is invalid", %{conn: conn, account_group: account_group, account: account} do
    contact = insert(:contact)
    insert(:account_group_contact, contact: contact, account_group: account_group)
    conn = put conn, account_path(conn, :update_setup, account, step: 3), account: %{"contact_id" => contact.id}
    assert html_response(conn, 200) =~ "Add Account"
  end

  test "deletes chosen contact", %{conn: conn, account_group: account_group, account: account} do
    contact = insert(:contact, last_name: "Navarro", type: "Corp Signatory")
    insert(:phone, number: "101", type: "mobile", contact: contact)
    insert(:account_group_contact, account_group: account_group, contact: contact)
    conn = delete conn, account_path(conn, :delete_account_contact, contact, account_id: account)
    assert conn.private[:phoenix_flash]["info"] =~ "Contact deleted successfully."
    assert redirected_to(conn) == "/accounts/#{account.id}/setup?step=3"
  end

  # test "renders form for new financial", %{conn: conn, account: account, account_group: account_group} do
  #   contact1 = insert(:contact, type: "Contact Person")
  #   contact2 = insert(:contact, type: "Corp Signatory")
  #   contact3 = insert(:contact, type: "Account Officer")
  #   insert(:phone, number: "101", type: "mobile", contact: contact1)
  #   insert(:phone, number: "101", type: "mobile", contact: contact2)
  #   insert(:account_group_contact, account_group: account_group, contact: contact1)
  #   insert(:account_group_contact, account_group: account_group, contact: contact2)
  #   insert(:account_group_contact, account_group: account_group, contact: contact3)
  #   conn = get conn, account_path(conn, :setup, account.id, step: 4)
  #   assert html_response(conn, 200) =~ "Bank Account"
  # end

  test "creates financial and redirects when data is valid",
       %{conn: conn, account: account} do
    conn =
      post conn,
      account_path(conn, :create_financial, account.account_group_id),
      account: %{
        account_tin: "AccountTIN",
        vat_status: "20% VAT-able",
        p_sched_of_payment: "ANNUAL",
        d_sched_of_payment: "ANNUAL",
        previous_carrier: "carrier",
        attched_point: "attached",
        revolving_fund: "fund",
        threshold_limit: "limit",
        account_name: "Medilink Bank Account",
        account_no: 12_345_678
      }

    assert redirected_to(conn) == "/accounts/#{account.id}/setup?step=5"
  end

  # test "does not create payment and renders errors when data is invalid",
  #       %{conn: conn, account: account}
  # do
  #   conn =
  #     post(conn,
  #          account_path(conn, :create_financial, account.account_group.id),
  #          account: %{})
  #   assert html_response(conn, 200) =~ "Add Account"
  # end

  test "updates chosen financial and redirects when data is valid",
       %{conn: conn, account_group: account_group, account: account}
  do
    insert(:bank, account_name: "Medilink Bank Account", account_group: account_group)
    insert(:payment_account, account_group: account_group)
    conn = put conn, account_path(conn, :update_setup, account, step: 4), account: %{
      mode_of_payment: "Electronic Debit",
      account_tin: "AccountTINTIN",
      vat_status: "20% VAT-able",
      p_sched_of_payment: "Daily",
      d_sched_of_payment: "Daily",
      previous_carrier: "carrier",
      attched_point: "attached",
      revolving_fund: "fund",
      threshold_limit: "limit",
      account_name: "MBank Account",
      account_no: 12_345_678
    }

    assert redirected_to(conn) == "/accounts/#{account.id}/setup?step=5"
  end

  # test "does not update chosen financial and renders errors when data is invalid", %{conn: conn, account_group: account_group, account: account} do
  #   insert(:payment_account, account_group: account_group)
  #   conn = put conn, account_path(conn, :update_setup, account, step: 4), account: %{}
  #   version = Enum.join([
  #     account.major_version,
  #     account.minor_version,
  #     account.build_version
  #   ], ".")
  #   assert html_response(conn, 200) =~ "Edit  v#{version}"
  # end

  test "renders form for new summary", %{conn: conn, industry: industry} do
    account_group = insert(:account_group, name: "name", code: "code", type: "corporate", industry: industry)
    account = insert(:account, account_group: account_group)

    conn = get conn, account_path(conn, :setup, account.id, step: 5)
    assert html_response(conn, 200) =~ "General"
    assert html_response(conn, 200) =~ "Address"
    assert html_response(conn, 200) =~ "Contact"
    # assert html_response(conn, 200) =~ "Financial"
  end

  test "create product and redirects when data is valid", %{conn: conn, account: account} do
    product1 = insert(:product,
        name: "name",
        description: "description",
        type: "type",
        limit_type: "limit_type",
        limit_amount: 12_000,
        limit_applicability: "Applicability",
        standard_product: "Yes"
    )
    product2 = insert(:product,
        name: "name2",
        description: "description",
        type: "type",
        limit_type: "limit_type",
        limit_amount: 12_000,
        limit_applicability: "Applicability",
        standard_product: "Yes"
    )

    insert(:account_product, account: account, product: product1)
    benefit1 = insert(:benefit)
    benefit2 = insert(:benefit)
    insert(:product_benefit, product: product1, benefit: benefit1)
    insert(:product_benefit, product: product1, benefit: benefit2)

    conn = post conn, account_path(conn, :create_product, account), account_product: %{product_ids: "#{product1.id},#{product2.id}", standard: "yes"}

    assert redirected_to(conn) == "/accounts/#{account.id}?active=product"
  end

  test "does not create product and renders errors when data is invalid", %{conn: conn, account: account} do
    conn = post conn, account_path(conn, :create_product, account), account_product: %{product_ids: ""}
    assert redirected_to(conn) == "/accounts/#{account.id}?active=product"
  end

  test "update product and redirects when data is valid",  %{conn: conn, account: account} do
    product = insert(:product, name: "Product1")
    account_product = insert(:account_product, product: product, account: account)
    conn = post conn, account_path(conn, :update_product, account), account_product: %{
      name: "Product",
      description: "description",
      type: "type",
      limit_type: "limit_type",
      limit_amount: 12_000,
      limit_applicability: "Applicability",
      account_id: account.id,
      account_product_id: account_product.id,
      product_id: product.id
    }

    assert redirected_to(conn) == "/accounts/#{account.id}?active=product"
  end

  test "does not update chosen product and renders errors when data is invalid", %{conn: conn, account: account} do
    product = insert(:product, name: "Product1")
    account_product = insert(:account_product, product: product, account: account)
    conn = post conn, account_path(conn, :update_product, account),
      account_product: %{account_product_id: account_product.id}
    assert html_response(conn, 200) =~ "blank"
  end

  test "delete account_product and redirects when success",  %{conn: conn} do
    account = insert(:account, status: "Active", minor_version: 1)
    product = insert(:product, name: "Product1")
    account_product = insert(:account_product, product: product, account: account)

    params = %{
      "ap_remove" =>
      %{"account_id" => account.id,
        "account_product_id" => account_product.id,
        "product_tier_ranking" => "1_" <> product.id
      }
    }

    conn = delete conn, account_path(conn, :delete_account_product, account.id), params

    assert redirected_to(conn) == "/accounts/#{account.id}?active=product"
  end

  test "delete account_product returns error when account product id is not valid",  %{conn: conn} do
    account = insert(:account, status: "Active", minor_version: 1)
    product = insert(:product, name: "Product1")
    insert(:account_product, product: product, account: account)

    params = %{
      "ap_remove" =>
      %{"account_id" => account.id,
        "account_product_id" => "530e4026-9e46-415f-bed2-64fadc96ecd6",
        "product_tier_ranking" => "1_" <> product.id
      }
    }

    conn = delete conn, account_path(conn, :delete_account_product, account.id), params

    assert conn.status == 302
    assert conn.private[:phoenix_flash]["error"] == "Error in Deleting Account Product!"
    assert redirected_to(conn) == "/accounts/#{account.id}?active=product"
  end

  test "updates expiry date of chosen account and redirects when data is valid", %{conn: conn} do
    account = insert(:account, end_date: Ecto.Date.cast!("2017-01-04"), status: "Active")
    account_group = insert(:account_group)
   conn = put conn, account_path(conn, :extend_account, account), account: %{
     end_date: Ecto.Date.cast!("2017-01-10"), account_id: account.id, account_group_id: account_group.id
    }
    assert conn.private[:phoenix_flash]["info"] =~ "Account successfully Extended!"
    assert redirected_to(conn) == "/accounts/#{account.id}?active=profile"
  end

  test "does not update expiry date of chosen account and renders errors when data is invalid", %{conn: conn} do
    account = insert(:account, end_date: Ecto.Date.cast!("2017-01-04"))
    conn = put conn, account_path(conn, :extend_account, account), account: %{account_id: account.id, end_date: ""}
    assert conn.private[:phoenix_flash]["error"] =~ "Status is not Active!"
    assert redirected_to(conn) == "/accounts/#{account.id}?active=profile"
  end

  test "add approver and redirects when success", %{conn: conn, account: account} do
    account_group = insert(:account_group)
    conn = post conn, account_path(conn, :create_approver, account.account_group.id), account: %{
      account_id: account.id,
      account_group_id: account_group.id,
      approval_name: "Raymond Navarro",
      approval_designation: "Software Engineer",
      approval_department: "SDDD",
      approval_email: "admin@example.com",
      approval_mobile: "092150000",
      approval_telephone: "63636364",
    }

    assert redirected_to(conn) == "/accounts/#{account.id}/setup?step=4"
  end

  test "Remove Approver", %{conn: conn, account_group: account_group, account: account} do
    account_group_approval = insert(:account_group_approval, account_group: account_group)
    conn = delete conn, account_path(conn, :delete_approver, account_group_approval, account)
    assert redirected_to(conn) == "/accounts/#{account.id}/setup?step=4"
  end

  test "suspend account in account page with valid attributes", %{conn: conn} do
    account = insert(:account)
    account_group = insert(:account_group)
    conn = post conn, account_path(conn, :suspend_account_in_account, account), account: %{
      "account_group_id" => account_group.id,
      "account_id" => account.id,
      "status" => "Suspend",
      "suspend_date" => "2017-09-02",
      "suspend_reason" => "others1",
      "suspend_remarks" => "Test"
    }

    assert conn.private[:phoenix_flash]["info"] =~ "Successfully suspend an account."
    assert redirected_to(conn) == "/accounts/#{account.id}?active=profile"
  end

 test "suspend account in account page with invalid attributes", %{conn: conn} do
    account = insert(:account)
    conn = post conn, account_path(conn, :suspend_account_in_account, account), account: %{
      "account_group_id" => "7ba4af7e-62ba-4090-99cf-529627feb553",
      "account_id" => account.id,
      "status" => "",
      "suspend_date" => "2017-09-02",
      "suspend_reason" => "others1",
      "suspend_remarks" => "Test"
    }

    assert conn.private[:phoenix_flash]["error"] =~ "Failed to suspend an account."
    assert redirected_to(conn) == "/accounts/#{account.id}?active=profile"
  end

  test "On click update financial with valid valid attr", %{conn: conn} do
    account_group = insert(:account_group)
    insert(:payment_account, account_group: account_group)
    conn = post conn, account_path(conn, :on_click_update, account_group.id), params: %{
      "approval_mode_of_payment" => "Electronic Debit",
      "approval_account_no" => "123456789",
      "approval_account_name" => "Medilink",
      "approval_authority_debit" =>  "yes",
      "account[account_tin]" => "AccountTINTIN",
      "account[vat_status]" => "20% VAT-able",
      "mode_of_payment" => "Check",
      "account[p_sched_of_payment]" => "Daily",
      "account[d_sched_of_payment]" => "Daily",
      "previous_carrier" => "carrier",
      "attched_point" => "attached",
      "revolving_fund" => "fund",
      "threshold_limit" => "limit",
      "account_name" => "MBank Account",
      "account_no" => 12_345_678
    }

    params = Poison.encode!("true")
    assert Poison.decode!(conn.resp_body) == params
  end

  test "Show account", %{conn: conn, industry: industry} do
    account_group = insert(:account_group, industry: industry)
    insert(:account_group_address, account_group: account_group)
    insert(:payment_account, account_group: account_group)
    account = insert(:account, step: 6, account_group: account_group, status: "Active")

    conn = get conn, account_path(conn, :show, account.id, active: "product")

    assert html_response(conn, 200) =~ "Profile"
    # assert html_response(conn, 200) =~ "Financial"
    assert html_response(conn, 200) =~ "Product"
    assert html_response(conn, 200) =~ "Fulfillment"
  end

  test "create_comment in account page with valid attributes", %{conn: conn} do
    account = insert(:account)
    user = insert(:user)
    insert(:account_comment)
    conn = post conn, account_path(conn, :create_account_comment, account),
    account_comment: %{"account_id" => account.id, "user_id" => user.id, "comment" => "comment101"}
    params = Poison.encode!(%{"account_id" => account.id, "user_id" => user.id, "comment" => "comment101"})
    assert Poison.decode!(conn.resp_body) == "#{params}"
  end

  test "create_comment in account page with invalid attributes", %{conn: conn} do
    account = insert(:account)
    user = insert(:user)
    insert(:account_comment)
    conn = post conn, account_path(conn, :create_account_comment, account),
          account_comment: %{"account_id" => account.id, "user_id" => user.id}
    assert conn.private[:phoenix_flash]["error"] =~ "Comment is required."
  end

  test "renew account in account page with valid attrs", %{conn: conn, account_group: account_group} do
    insert(:account, account_group: account_group)
    account = insert(:account, status: "Active", account_group: account_group, step: 6, major_version: 1)
    product = insert(:product)
    benefit = insert(:benefit)
    insert(:product_benefit, product: product, benefit: benefit)
    insert(:account_product, account: account, product: product)
    conn = post conn, account_path(conn, :renew_account, account)

    assert %{id: id} = redirected_params(conn)
    assert conn.private[:phoenix_flash]["info"] =~ "Account new version successfully created."
    assert redirected_to(conn) == "/accounts/#{id}/edit?step=1"
  end

  test "renew account in account page with invalid attrs", %{conn: conn, account_group: account_group} do
    account = insert(:account, status: "Active", account_group: account_group, major_version: 1)
    conn = post conn, account_path(conn, :renew_account, account)

    assert conn.private[:phoenix_flash]["error"] =~ "Failed to renew due to incomplete data."
    assert redirected_to(conn) == "/accounts/#{account.id}?active=profile"
  end

  test "renew account in account page with pending status", %{conn: conn, account_group: account_group} do
    account = insert(:account, status: "Pending", account_group: account_group, major_version: 1)
    conn = post conn, account_path(conn, :renew_account, account)

    assert conn.private[:phoenix_flash]["error"] =~ "The status of account should be active or lapsed to renew."
    assert redirected_to(conn) == "/accounts/#{account.id}?active=profile"
  end

  test "activate account with for activation status", %{conn: conn, account_group: account_group} do
    start_date = Ecto.Date.cast!("2017-01-01")
    end_date = Ecto.Date.cast!("2017-01-10")
    account = insert(:account, status: "For Activation", account_group: account_group, start_date: start_date, end_date: end_date)
    conn = post conn, account_path(conn, :activate_account, account), account: %{status: "For Renewal"}

    assert conn.private[:phoenix_flash]["info"] =~ "Renewal successfully activated."
    assert redirected_to(conn) == "/accounts/#{account.account_group_id}/versions"
  end

  test "activate account with status is not For Activation redirects with error", %{conn: conn, account_group: account_group} do
    start_date = Ecto.Date.cast!("2017-01-01")
    end_date = Ecto.Date.cast!("2017-01-10")
    account = insert(:account, start_date: start_date, end_date: end_date, status: "For Renewal", account_group: account_group)
    conn = post conn, account_path(conn, :activate_account, account), account: %{status: "For Renewal"}

    assert conn.private[:phoenix_flash]["error"] =~ "Failed to activate due to status is not for activation."
    assert redirected_to(conn) == "/accounts/#{account.id}?active=profile"
  end

  test "activate account without status redirects with error", %{conn: conn, account_group: account_group} do
    start_date = Ecto.Date.cast!("2017-01-01")
    end_date = Ecto.Date.cast!("2017-01-10")
    account = insert(:account, start_date: start_date, end_date: end_date, status: "For Activation", account_group: account_group)
    conn = post conn, account_path(conn, :activate_account, account), account: %{status: ""}

    assert conn.private[:phoenix_flash]["error"] =~ "Account status is required."
    assert redirected_to(conn) == "/accounts/#{account.id}?active=profile"
  end

  test "cancel renewal account with for activation status", %{conn: conn, account_group: account_group} do
    account = insert(:account, status: "For Activation", account_group: account_group)
    conn = post conn, account_path(conn, :cancel_renewal, account), account: %{status: "Renewal Cancelled"}

    assert conn.private[:phoenix_flash]["info"] =~ "Account status is now renewal cancelled"
    assert redirected_to(conn) == "/accounts/#{account.account_group_id}/versions"
  end

  test "cancel renewal account with status is not For Activation redirects with error", %{conn: conn, account_group: account_group} do
    account = insert(:account, status: "For Renewal", account_group: account_group)
    conn = post conn, account_path(conn, :cancel_renewal, account), account: %{status: "For Renewal"}

    assert conn.private[:phoenix_flash]["error"] =~ "Failed to activate due to status is not for activation."
    assert redirected_to(conn) == "/accounts/#{account.id}?active=profile"
  end

  test "cancel account without status redirects with error", %{conn: conn, account_group: account_group} do
    account = insert(:account, status: "For Activation", account_group: account_group)
    conn = post conn, account_path(conn, :cancel_renewal, account), account: %{status: ""}

    assert conn.private[:phoenix_flash]["error"] =~ "Account status is required."
    assert redirected_to(conn) == "/accounts/#{account.id}?active=profile"
  end

  # test "print_account with valid attributes", %{conn: conn} do
  #   account_group = insert(:account_group)
  #   account = insert(:account, account_group: account_group)

  #   conn = get conn, account_path(conn, :print_account, account.id)

  #   assert get_resp_header(conn, "content-type") == ["application/pdf; charset=utf-8"]
  # end

  # test "print_account with invalid attributes", %{conn: conn} do
  #   account_group = insert(:account_group)
  #   account = insert(:account, account_group: account_group)

  #   conn = get conn, account_path(conn, :print_account, account.id)

  #   # refute get_resp_header(conn, "content-type") == ["application/text; charset=utf-8"]
  #   assert conn.private[:phoenix_flash]["error"] =~ "Failed to print account."
  # end

  test "reactivate_account_in_account in account page with valid attributes", %{conn: conn} do
    account = insert(:account)
    account_group = insert(:account_group)
    conn = post conn, account_path(conn, :reactivate_account_in_account, account), account: %{
      "account_group_id" => account_group.id,
      "account_id" => account.id,
      "status" => "Active",
      "reactivate_date" => "2017-09-02",
      "reactivate_remarks" => "Test",
      "module" => "Account"
    }

    assert conn.private[:phoenix_flash]["info"] =~ "Successfully reactivate an account."
    assert redirected_to(conn) == "/accounts/#{account.id}?active=profile"
  end

  test "reactivate_account_in_account in account page with invalid attributes", %{conn: conn} do
    account = insert(:account)
    conn = post conn, account_path(conn, :reactivate_account_in_account, account), account: %{
      "account_group_id" => "7da4af7e-62ba-4090-99cf-529627feb553",
      "account_id" => account.id,
      "status" => "",
      "reactivate_date" => "",
      "reactivate_remarks" => "Test",
      "module" => "Account"
    }

    assert conn.private[:phoenix_flash]["error"] =~ "Failed to reactivate an account."
    assert redirected_to(conn) == "/accounts/#{account.id}?active=profile"
  end

  test "download_accounts with valid data", %{conn: conn} do
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
    payment_account = insert(:payment_account, account_group: account_group, funding_arrangement: "ASO")
    cluster = insert(:cluster, industry: industry, code: "cl01", name: "cluster 01")
    insert(:account_group_cluster, account_group: account_group, cluster: cluster)
    codes = %{"params" => [account_group.code]}

    conn = post conn, account_path(conn, :download_accounts, codes)

    assert json_response(conn, 200) == Poison.encode!([%{
      cluster_code: cluster.code, cluster_name: cluster.name, code: account_group.code,
      created_by: user.username, date_created: account.inserted_at, end_date: account.end_date,
      funding: payment_account.funding_arrangement, industry: industry.code, name: account_group.name,
      segment: account_group.segment, start_date: account.start_date, status: account.status,
      version: "#{account.major_version}.#{account.minor_version}.#{account.build_version}"
    }])
  end

  test "retract account suspension date", %{conn: conn} do
    account = insert(:account, suspend_date: "2017-10-16")
    conn = post conn, account_path(conn, :retract_account, account), account: %{movement: "Suspension"}

    assert conn.private[:phoenix_flash]["info"] =~ "Account movement is retracted."
    assert redirected_to(conn) == "/accounts/#{account.id}?active=profile"
  end

  test "retract account cancellation date", %{conn: conn} do
    account = insert(:account, cancel_date: "2017-10-16")
    conn = post conn, account_path(conn, :retract_account, account), account: %{movement: "Cancellation"}

    assert conn.private[:phoenix_flash]["info"] =~ "Account movement is retracted."
    assert redirected_to(conn) == "/accounts/#{account.id}?active=profile"
  end

  test "retract account reactivation date", %{conn: conn} do
    account = insert(:account, reactivate_date: "2017-10-16")
    conn = post conn, account_path(conn, :retract_account, account), account: %{movement: "Reactivation"}

    assert conn.private[:phoenix_flash]["info"] =~ "Account movement is retracted."
    assert redirected_to(conn) == "/accounts/#{account.id}?active=profile"
  end

  test "retract account movement with invalid attrs", %{conn: conn} do
    account = insert(:account, reactivate_date: "2017-10-16")
    conn = post conn, account_path(conn, :retract_account, account), account: %{movement: ""}

    assert conn.private[:phoenix_flash]["error"] =~ "Error retracting movement"
    assert redirected_to(conn) == "/accounts/#{account.id}?active=profile"
  end

  test "save_hoed/2, saves hoed records with valid data", %{conn: conn} do
    account_group = insert(:account_group)
    account = insert(:account, account_group: account_group)

    account_params = %{
      "me_sortable" => "1-Spouse",
      "se_sortable" => "1-Sibling",
      "spe_sortable" => "1-Child"
    }

    conn = post conn, account_path(conn, :save_ahoed, account), account_id: account.id, account_params: account_params

    assert json_response(conn, 200) == Poison.encode!("success")
  end

  test "save_hoed/2, saves hoed records with invalid data", %{conn: conn} do
    account = insert(:account)

    account_params = %{
      "me_sortable" => "1-Spouse",
      "se_sortable" => "1-Sibling",
      "spe_sortable" => ""
    }

    conn = post conn, account_path(conn, :save_ahoed, account), account_id: account.id, account_params: account_params

    assert json_response(conn, 200) == Poison.encode!("fail")
  end
end
