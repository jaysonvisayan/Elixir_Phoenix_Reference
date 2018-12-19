defmodule AccountLinkWeb.AccountControllerTest do
  use AccountLinkWeb.ConnCase
  use Innerpeace.Db.SchemaCase, async: true

  alias AccountLink.Guardian.Plug
  alias Innerpeace.Db.Schemas.{
    AccountGroup,
    AccountGroupAddress,
    PaymentAccount,
    Bank,
    User,
    UserAccount
  }

  setup do
    industry = insert(:industry, code: "101")
    {:ok, account_group} = Repo.insert(%AccountGroup{
      name: "Account01",
      code: "12345",
      industry_id: industry.id
    })
    Repo.insert(%AccountGroupAddress{
      account_group: account_group
    })
    Repo.insert(%PaymentAccount{
      account_group: account_group
    })
    Repo.insert(%Bank{
      account_group: account_group
    })

    account = insert(
      :account,
      account_group: account_group,
      major_version: 1,
      minor_version: 0,
      build_version: 0,
      status: "Active"
    )
    product = insert(:product, code: "Product01")
    insert(
      :account_product,
      account: account,
      product: product
    )

    {:ok, user} = Repo.insert(%User{
      username: "accountlinkuser", password: "P@ssw0rd"
    })
    Repo.insert(%UserAccount{
      user_id: user.id, account_group_id: account_group.id
    })

    conn = AccountLinkWeb.Auth.login(build_conn(), user)
    jwt = Plug.current_token(conn)

    {:ok, %{
      conn: conn,
      jwt: jwt,
      user: user,
      account_group: account_group,
      account: account,
      product: product
    }}
  end

  test "show_profile of account", %{conn: conn, account_group: account_group} do
    conn = get conn, account_path(conn, :show_profile, @locale)
    assert html_response(conn, 200) =~ account_group.name
  end

  test "show_product of account", %{conn: conn, product: product} do
    conn = get conn, account_path(conn, :show_product, @locale)

    assert html_response(conn, 200) =~ "View"
    assert html_response(conn, 200) =~ product.code
  end

  test "show_product_summary of account product", %{conn: conn, product: product} do
    conn = get conn, account_path(conn, :show_product_summary, @locale, product)

    assert html_response(conn, 200) =~ "General"
    assert html_response(conn, 200) =~ product.name
  end

  test "show_finance of account", %{conn: conn} do
    conn = get conn, account_path(conn, :show_finance, @locale)
    assert html_response(conn, 200) =~ "Signatory"
  end

  test "get_account api", %{conn: conn, account_group: account_group} do
    conn = get conn, account_path(conn, :get_account, @locale, account_group.code)
    assert json_response(conn, 200)["id"] == account_group.id
  end
end
