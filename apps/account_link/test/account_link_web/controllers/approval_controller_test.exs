defmodule AccountLinkWeb.ApprovalControllerTest do
  use AccountLinkWeb.ConnCase
  use Innerpeace.Db.SchemaCase, async: true

  alias AccountLink.Guardian.Plug
  alias Innerpeace.Db.Schemas.{
    # Authorization,
    # AuthorizationAmount,
    User,
    UserAccount,
    AccountGroup
  }

  setup do
    dropdown =
      insert(
        :dropdown,
        type: "Special Approval",
        text: "Corporate Guarantee"
      )
    authorization =
      insert(
        :authorization,
        special_approval: dropdown,
        status: "For Approval"
      )
    authorization_amount =
      insert(
        :authorization_amount,
        authorization: authorization,
        member_covered: "10",
        payor_covered: "10",
        company_covered: "10"
      )
    industry = insert(:industry, code: "101")
    {:ok, account_group} = Repo.insert(%AccountGroup{
      name: "Account01",
      code: "12345",
      industry_id: industry.id
    })

    {:ok, user} = Repo.insert(%User{
      username: "accountlinkuser", password: "P@ssw0rd"
    })
    Repo.insert(%UserAccount{
      user_id: user.id, account_group_id: account_group.id
    })

    conn = AccountLinkWeb.Auth.login(build_conn(), user)

    {:ok, %{
      conn: conn,
      user: user,
      account_group: account_group,
      authorization: authorization,
      authorization_amount: authorization_amount
    }}
  end

  test "show special", %{conn: conn} do
    conn = get conn, approval_path(conn, :show_special, @locale)
    assert html_response(conn, 200)
  end

  test "show special details", %{conn: conn, authorization: authorization} do
    conn = get conn, approval_path(conn, :show_special_details, @locale, authorization.id)
    assert html_response(conn, 200) =~ "Pending"
  end

  test "special action for approve", %{conn: conn, authorization_amount: authorization_amount} do
    params = %{
      member_covered: "20",
      payor_covered: "20",
      company_covered: "20",
      action: "Approve"
    }

    conn =
      put conn, approval_path(
        conn,
        :special_action,
        @locale,
        authorization_amount.id,
        authorization_amount: params
      )

    assert html_response(conn, 200)
  end

  test "special action for reject", %{conn: conn, authorization_amount: authorization_amount} do
    params = %{
      reason: "reason for rejection",
      action: "Reject"
    }

    conn =
      put conn, approval_path(
        conn,
        :special_action,
        @locale,
        authorization_amount.id,
        authorization_amount: params
      )

    assert html_response(conn, 200)
  end

  test "download csv file of special approval", %{conn: conn} do
    special_param =  %{"search_value" => "For Approval"}
    conn = get conn, api_approval_path(conn, :download_special, special_param: special_param)
    assert json_response(conn, 200)
  end
end
