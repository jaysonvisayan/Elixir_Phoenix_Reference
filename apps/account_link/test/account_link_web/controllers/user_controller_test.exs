defmodule AccountLinkWeb.UserControllerTest do
  use AccountLinkWeb.ConnCase
  use Innerpeace.Db.SchemaCase, async: true

  alias Innerpeace.Db.Schemas.{
    AccountGroup,
    AccountGroupAddress
  }

  setup do
    conn = build_conn() |> assign(:locale, "en")
    industry = insert(:industry, code: "101")
    {:ok, account_group} = Repo.insert(%AccountGroup{
      name: "Account01",
      code: "Account01",
      type: "Headquarters",
      segment: "Corporate",
      industry_id: industry.id
    })
    insert(:account, account_group: account_group)
    Repo.insert(%AccountGroupAddress{
      line_1: "101",
      line_2: "name",
      type: "company address",
      account_group_id: account_group.id,
      postal_code: "4001",
      city: "city",
      province: "province",
      country: "country",
      region: "region"
    })

    {:ok, %{
      conn: conn,
      account_group: account_group
    }}
  end

  test "render user register", %{conn: conn, account_group: account_group} do
    conn = get conn, user_path(conn, :register, @locale, account_group)

    assert html_response(conn, 200) =~ "Account Information Form"
  end

  test "register with valid params", %{conn: conn, account_group: account_group} do
    params = %{
      first_name: "Testa",
      last_name: "Testa",
      gender: "Male",
      role: "hr_admin",
      username: "testa123",
      password: "P@ssw0rd",
      confirm_password: "P@ssw0rd",
      email: "testa@email.com",
      mobile: "09271242058"
    }

    conn = post conn, user_path(conn, :sign_up, @locale, account_group, user: params)

    assert html_response(conn, 200) =~ "successfully registered"
  end

  test "register with invalid params", %{conn: conn, account_group: account_group} do
    params = %{
      first_name: "Testa"
    }

    conn = post conn, user_path(conn, :sign_up, @locale, account_group, user: params)

    assert html_response(conn, 200) =~ "Please enter"
  end

  test "user_validate", %{conn: conn} do
    conn = get conn, user_path(conn, :user_validate, @locale)
    assert json_response(conn, 200)
  end
end
