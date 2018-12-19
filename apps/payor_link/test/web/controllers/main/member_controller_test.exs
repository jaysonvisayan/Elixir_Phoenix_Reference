defmodule Innerpeace.PayorLink.Web.Main.MemberControllerTest do
    use Innerpeace.PayorLink.Web.ConnCase

    setup do
      conn = build_conn()
      # user = insert(:user, is_admin: true)
      # conn = sign_in(conn, user)
      user = fixture(:user_permission, %{keyword: "manage_members", module: "Members"})
      conn = authenticated(conn, user)
      account_group = insert(:account_group, name: "account101")
      insert(:account, account_group: account_group, status: "Active")
      insert(:coverage, name: "ACU", description: "ACU", status: "A", type: "A")
      member = insert(:member, %{
        first_name: "test",
        account_group: account_group
      })
      {:ok, %{conn: conn, member: member}}
    end

    test "list all entries on batch", %{conn: conn} do
        conn = get conn, main_member_path(conn, :batch_processing)
        assert html_response(conn, 200) =~ "Batch"
    end

    test "get_pwd_id/0, get all the pwd_id of members", %{conn: conn} do
      member = insert(:member, pwd_id: "12345", senior_id: "67890")
      conn = get conn, main_member_path(conn, :get_pwd_id)
      assert json_response(conn, 200) == Poison.encode!([member.pwd_id])
    end

    test "get_senior_id/0, get all the senior_id of members", %{conn: conn} do
      member = insert(:member, pwd_id: "12345", senior_id: "67890")
      conn = get conn, main_member_path(conn, :get_senior_id)
      assert json_response(conn, 200) == Poison.encode!([member.senior_id])
    end

    test "creating draft member in step 1 and redirect to index page", %{conn: conn} do
      account_group = insert(:account_group, code: "code123")
      params = %{
        first_name: "Luffy",
        last_name: "Monkey",
        account_code: account_group.code,
        effectivity_date: "2017-06-01",
        expiry_date: "2018-06-01",
        is_draft: "true",
        skipping_hierarchy: [""]
      }
      conn = post conn, main_member_path(conn, :create_general), member: params
      assert redirected_to(conn) == "/web/members"
    end

    test "creating draft member in step 2 and redirect to index page", %{conn: conn, member: member} do
      params = %{
        email: "monkeyDluffy@gmail.com",
        mobile: "09123456789",
        save_as_draft: "yes"
      }
      conn = post conn, main_member_path(conn, :update_setup, member, step: "2", member: params)
      assert redirected_to(conn) == "/web/members"
    end

    describe "delete member products" do
      test "with valid parameters", %{conn: conn, member: member} do
        ag = insert(:account_group, code: "code123")
        account = insert(:account, account_group: ag)
        product = insert(:product, code: "TEST", name: "TEST2")
        account_product = insert(:account_product, account: account, product: product, rank: 1)
        member_product = insert(:member_product, member: member, account_product: account_product, tier: 1)

        conn = delete conn, main_member_path(conn, :delete_member_product, member, member_product)
        assert json_response(conn, 200) == Poison.encode!(%{valid: true})
      end

      test "with invalid parameters no member products", %{conn: conn, member: member} do

        ag = insert(:account_group, code: "code123")
        account = insert(:account, account_group: ag)
        product = insert(:product, code: "TEST", name: "TEST2")
        account_product = insert(:account_product, account: account, product: product, rank: 1)
        id = "23db9bea-7572-4640-a565-c828d799ef5c"
        conn = delete conn, main_member_path(conn, :delete_member_product, member, id)

        assert json_response(conn, 200) == Poison.encode!(%{valid: false, coverage: "other"})
      end
    end

end
