defmodule AccountLinkWeb.PemeControllerTest do
  use AccountLinkWeb.ConnCase
  use Innerpeace.Db.SchemaCase, async: true

  alias AccountLink.Guardian.Plug

  alias Innerpeace.Db.Schemas.{
    User,
    Benefit,
    BenefitCoverage,
    BenefitPackage,
    ProductBenefit,
    AccountGroup,
    UserAccount,
  }

  setup do
    {:ok, account_group} = Repo.insert(%AccountGroup{code: "12345"})
    coverage = insert(:coverage, description: "PEME", code: "PEME")
    package = insert(:package)
    procedure = insert(:procedure, description: "MIR Scan", code: "MIR101")
    payor_procedure = insert(:payor_procedure, procedure: procedure)
    insert(:package_payor_procedure, payor_procedure: payor_procedure, package: package)
    {:ok, benefit} = Repo.insert(%Benefit{name: "Accenture Benefit", peme: true})
    Repo.insert(%BenefitPackage{benefit: benefit, package: package})
    Repo.insert(%BenefitCoverage{coverage: coverage, benefit: benefit})
    product = insert(:product, name: "product1", product_category: "PEME Plan")
    {:ok, _product_benefit} = Repo.insert(%ProductBenefit{benefit_id: benefit.id, product: product})
    product_coverage = insert(:product_coverage,
                              product: product,
                              coverage: coverage)
    facility = insert(:facility, name: "CALAMBA MEDICAL CENTER",
                      status: "Affiliated",
                      affiliation_date: "2017-11-10",
                      disaffiliation_date: "2018-11-23",
                      step: 7
    )
    insert(:product_coverage_facility, facility: facility, product_coverage: product_coverage)
    account = insert(:account,
                     account_group: account_group,
                     start_date: Ecto.Date.cast!("2018-01-01"),
                     end_date: Ecto.Date.cast!("2020-01-01"),
                     status: "Active",
                     major_version: 1)
    insert(:account_product, account: account, product: product)

    {:ok, user} = Repo.insert(%User{username: "masteradmin", password: "P@ssw0rd"})
    Repo.insert(%UserAccount{user_id: user.id, account_group_id: account_group.id})
    conn = AccountLinkWeb.Auth.login(build_conn(), user)
    jwt = Plug.current_token(conn)
    member = insert(:member,
                    account_group: account_group,
                    account_code: account_group.code,
                    first_name: "Test01",
                    last_name: "Test01",
                    expiry_date: Ecto.Date.cast!("2020-01-01"),
                    effectivity_date: Ecto.Date.cast!("2018-01-01"))
    peme = insert(:peme,
                    member: member,
                    evoucher_number: "PEME-123456",
                    evoucher_qrcode: "PEME-123456|Package01",
                    date_from: Ecto.Date.cast!("2018-01-01"),
                    date_to: Ecto.Date.cast!("2018-01-01"),
                    package: package,
                    status: "Issued")

    {:ok, %{
      member: member,
      package: package,
      facility: facility,
      peme: peme,
      jwt: jwt,
      conn: conn,
      user: user,
      account_group: account_group
    }}
  end

  test "render peme index", %{conn: conn} do
    conn = get conn, peme_path(conn, :index, @locale)
    assert html_response(conn, 200) =~ "peme"
  end

  test "render new peme", %{conn: conn} do
    conn = get conn, peme_path(conn, :new_peme, @locale)
    assert html_response(conn, 200) =~ "peme"
  end

  # test "peme generate evoucher with valid attributes", %{conn: conn, package: package, facility: facility} do
  #   params = %{
  #     package_id: package.id,
  #     facility_id: facility.id,
  #     date_from: Ecto.Date.utc(),
  #     date_to: Ecto.Date.utc(),
  #     member_count: "1"
  #   }
  #   conn = post conn, peme_path(conn, :peme_generate_evoucher, @locale), peme: params
  #   assert redirected_to(conn) == peme_path(conn, :index, @locale)
  # end

  test "peme generate evoucher with valid attributes", %{conn: conn, package: package, facility: facility} do
    params = %{
       package_id: package.id,
       facility_id: facility.id,
       date_from: "2018-08-01",
       date_to: "2019-08-15",
       member_count: "1"
    }
      conn = post conn, peme_path(conn, :peme_generate_evoucher, @locale), peme: params
      assert redirected_to(conn) == peme_path(conn, :index, @locale)
  end

  test "peme generate evoucher with invalid attributes", %{conn: conn, facility: facility} do
    params = %{
      facility_id: facility.id,
      type: "Single",
      member_count: "1"
    }
    conn = post conn, peme_path(conn, :peme_generate_evoucher, @locale), peme: params
    assert redirected_to(conn) == peme_path(conn, :new_peme, @locale)
  end

  # test "show_peme_summary/2, redirects user to summary", %{conn: conn, member: member} do
  #   package = insert(:package)
  #   params = %{
  #     locale: "en",
  #     id: member.id
  #   }

  #   conn = get conn, peme_path(conn, :show_peme_summary, @locale, member.id)
  #   assert html_response(conn, 200) =~ "Peme"
  # end

  #   test "show peme member details test", %{conn: conn, package: package, facility: facility} do
  #     {:ok, peme} = Repo.insert(%Peme{
  #                   package_id: package.id,
  #                   facility_id: facility.id,
  #                   date_from: Ecto.Date.utc(),
  #                   date_to: Ecto.Date.utc(),
  #                   type: "Single"
  #     })
  #     conn = get conn, peme_path(conn, :show_peme_member_details, @locale, peme.id, show_swall: "true")
  #     assert html_response(conn, 200) =~ "peme"
  #   end

  # test "render member index", %{conn: conn} do
  #   conn = get conn, member_path(conn, :index, @locale)
  #   assert html_response(conn, 200) =~ "Member"
  # end

  # test "new_single/2, renders form for enrollment of new PEME Member", %{conn: conn} do
  #   conn = get conn, peme_path(conn, :new_single, @locale)
  #   assert html_response(conn, 200) =~ "General"
  #   assert html_response(conn, 200) =~ "Personal Information"
  # end

  # test "show_single/2, redirects user to each form -- general form", %{conn: conn, member: member} do
  #   id = member.id
  #   conn = get conn, peme_path(conn, :show_single, @locale, id, step: "1")
  #   assert html_response(conn, 200) =~ "General"
  #   assert html_response(conn, 200) =~ "Personal Information"
  # end

  # test "show_single/2, redirects user to each form -- contact form", %{conn: conn, member: member} do
  #   id = member.id
  #   conn = get conn, peme_path(conn, :show_single, @locale, id, step: "2")
  #   assert html_response(conn, 200) =~ "Contact"
  #   assert html_response(conn, 200) =~ "Email"
  #   assert html_response(conn, 200) =~ "Mobile"
  # end

  # test "show_single/2, redirects user to each form -- request loa form", %{conn: conn, member: member} do
  #   conn = get conn, peme_path(conn, :show_single, @locale, member.id, step: "3")
  #   assert html_response(conn, 200) =~ "Request PEME"
  #   assert html_response(conn, 200) =~ "PEME Date"
  # end

  # test "show_summary/2, redirects user to summary", %{conn: conn, member: member} do
  #   package = insert(:package)
  #   params = %{
  #     member_id: member.id,
  #     package_id: package.id,
  #     peme_date: Ecto.Date.cast!("1999-11-11")
  #   }

  #   MemberContext.single_peme_request_loa(params)
  #   conn = get conn, peme_path(conn, :show_summary, @locale, member.id)
  #   assert html_response(conn, 200) =~ "LOA Details"
  # end

end
