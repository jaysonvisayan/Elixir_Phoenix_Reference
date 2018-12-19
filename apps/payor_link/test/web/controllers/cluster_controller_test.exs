defmodule Innerpeace.PayorLink.Web.ClusterControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper

  # @create_attrs %{
  #   name: "AccountName",
  #   type: "Corporate",
  #   code: "AccountCode"
  # }
  setup do
    conn = build_conn()
    account = insert(:account, step: 1)
    insert(:account_group)
    # user = insert(:user, is_admin: true)
    # conn = sign_in(conn, user)
    user = fixture(:user_permission, %{keyword: "manage_clusters", module: "Clusters"})
    conn = authenticated(conn, user)
    {:ok, %{conn: conn, user: user, account: account}}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, cluster_path(conn, :index)
    assert html_response(conn, 200) =~ "Cluster"
  end

  test "renders form for new clusters", %{conn: conn} do
    conn = get conn, cluster_path(conn, :new)
    assert html_response(conn, 200) =~ "Add Cluster"
  end

  test "creates cluster and redirects to show when data is valid", %{conn: conn} do
    conn = post conn, cluster_path(conn, :create), cluster: %{name: "Cluster Name", code: "Cluster Code", step: 2}
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == "/clusters/#{id}/setup?step=2"
  end

  test "does not create cluster and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, cluster_path(conn, :create), cluster: %{name: "nil"}
    assert html_response(conn, 200) =~ "Add Cluster"
  end

  test "renders form for renew account", %{conn: conn} do
    cluster = insert(:cluster)
    account_group = insert(:account_group)
    account = insert(:account, account_group: account_group, status: "Active")
    conn = get conn, cluster_path(conn, :account_movements, cluster.id, account.id)
    assert html_response(conn, 200) =~ "View Account"
  end

  test "updates chosen cluster and redirects when data is valid", %{conn: conn} do
    cluster = insert(:cluster)
    conn = put conn, cluster_path(conn, :update_setup, cluster, step: 1),
    cluster: %{code: "Code", name: "Cluster Test"}
    assert redirected_to(conn) == "/clusters/#{cluster.id}/setup?step=2"
  end

  test "deletes chosen cluster", %{conn: conn} do
    cluster = insert(:cluster)
    conn = delete conn, cluster_path(conn, :delete, cluster)
    assert redirected_to(conn) == cluster_path(conn, :index)
  end

  test "renders form for step 2 of the given cluster", %{conn: conn} do
    cluster = insert(:cluster)
    account_group = insert(:account_group)
    insert(:payment_account, account_group: account_group)
    conn = get conn, cluster_path(conn, :setup, cluster, step: "2")
    assert html_response(conn, 200) =~ "Account"
  end

  test "step 2 adds account with valid attributes", %{conn: conn} do
    cluster = insert(:cluster)
    account_group = insert(:account_group)
    insert(:account_group_cluster, account_group: account_group, cluster: cluster)
    params = %{
      "account_group_cluster_ids_main" => "#{account_group.id}"
    }
    conn = post conn, cluster_path(conn, :update_setup, cluster, step: "2", cluster: params)
    assert redirected_to(conn) == cluster_path(conn, :setup, cluster, step: "2")
  end

  test "step 2 does not add clusters with invalid attributes", %{conn: conn} do
    insert(:account)
    cluster = insert(:cluster, code: "test")
    account_group = insert(:account_group)
    insert(:account_group_cluster, account_group: account_group, cluster: cluster)
    params = %{
      "account_group_cluster_ids_main" => ""
    }
    conn = post conn, cluster_path(conn, :update_setup, cluster, step: "2", cluster: params)
    assert html_response(conn, 200) =~ "Cluster"

  end

  test "renders form for step 3 of the given cluster", %{conn: conn} do
    insert(:account)
    cluster = insert(:cluster)
    account_group = insert(:account_group)
    insert(:account_group_cluster, account_group: account_group, cluster: cluster)
    conn = get conn, cluster_path(conn, :setup, cluster, step: "3")
    assert html_response(conn, 200) =~ "Cluster"
    assert html_response(conn, 200) =~ "Account"
  end

  test "cancel an account with invalid attributes", %{conn: conn} do
    cluster = insert(:cluster)
    account_group = insert(:account_group)
    account = insert(:account, account_group: account_group)
    conn = post conn, cluster_path(conn, :update_cancel), cluster: %{"account_group_id" => account_group.id, "account_id" => account.id, "cluster_id" => cluster.id, "status" => "", "suspend_date" => "2017-01-01", "suspend_reason" => "a", "suspend_remarks" => "others"}

    assert conn.private[:phoenix_flash]["error"] =~ "Error upon cancelling account."
    assert redirected_to(conn) ==  "/clusters/#{cluster.id}/accounts/#{account.id}"
  end

  test "suspend an account with valid attributes", %{conn: conn} do
    cluster = insert(:cluster)
    account_group = insert(:account_group)
    account = insert(:account, account_group: account_group)
    conn = post conn, cluster_path(conn, :update_suspend), cluster: %{"account_group_id" => account_group.id, "account_id" => account.id, "cluster_id" => cluster.id, "status" => "active", "suspend_date" => "2017-01-01", "suspend_reason" => "a", "suspend_remarks" => "others"}

    assert conn.private[:phoenix_flash]["info"] =~ "Successfully suspend an account."
    assert redirected_to(conn) ==  "/clusters/#{cluster.id}/accounts/#{account.id}"
  end


  test "suspend an account with invalid attributes", %{conn: conn} do
    cluster = insert(:cluster)
    account_group = insert(:account_group)
    account = insert(:account, account_group: account_group)
    conn = post conn, cluster_path(conn, :update_suspend), cluster: %{"account_group_id" => account_group.id, "account_id" => account.id, "cluster_id" => cluster.id, "status" => "", "suspend_date" => "2017-01-01", "suspend_reason" => "a", "suspend_remarks" => "others"}

    assert conn.private[:phoenix_flash]["error"] =~ "Error upon suspending an account."
    assert redirected_to(conn) ==  "/clusters/#{cluster.id}/accounts/#{account.id}"
  end

  test "extend an account with valid attributes", %{conn: conn} do
    cluster = insert(:cluster)
    account_group = insert(:account_group)
    account = insert(:account, account_group: account_group)
    conn = post conn, cluster_path(conn, :update_extend), cluster: %{"cluster_id" => cluster.id, "account_group_id" => account_group.id, "account_id" => account.id, "end_date" => "2017-09-01"}

    assert conn.private[:phoenix_flash]["info"] =~ "Account Extended Successfully."
    assert redirected_to(conn) == "/clusters/#{cluster.id}/accounts/#{account.id}"
  end

  test "extend an account with invalid attributes", %{conn: conn} do
    cluster = insert(:cluster)
    account_group = insert(:account_group)
    account = insert(:account, account_group: account_group)
    conn = post conn, cluster_path(conn, :update_extend), cluster: %{"cluster_id" => cluster.id, "account_group_id" => account_group.id, "account_id" => account.id}

    assert conn.private[:phoenix_flash]["error"] =~ "Error upon extension of account."
    assert redirected_to(conn) == "/clusters/#{cluster.id}/accounts/#{account.id}"
  end

  test "renew an account with valid attributes", %{conn: conn} do
    cluster = insert(:cluster)
    account_group = insert(:account_group)
    account = insert(:account, step: 6, account_group: account_group, status: "Active", start_date: "2017-01-01", major_version: 1)
    conn = post conn, cluster_path(conn, :update_renew), cluster: %{"account_group_id" => account_group.id, "account_id" => account.id, "cluster_id" => cluster.id, "status" => "active", "start_date" => "2017-01-01", "end_date" => "2018-01-01"}

    assert conn.private[:phoenix_flash]["info"] =~ "Account will be renewed on #{account.start_date}"
    assert redirected_to(conn) ==  "/clusters/#{cluster.id}/accounts/#{account.id}"
  end


  test "renew an account with invalid attributes", %{conn: conn} do
    cluster = insert(:cluster)
    account_group = insert(:account_group)
    account = insert(:account, account_group: account_group)
    conn = post conn, cluster_path(conn, :update_renew), cluster: %{"account_group_id" => account_group.id, "account_id" => account.id, "cluster_id" => cluster.id}


    assert redirected_to(conn) ==  "/clusters/#{cluster.id}/accounts/#{account.id}"
  end

  test "edit_general, updating cluster general tab with valid attrs", %{conn: conn} do
    cluster = insert(:cluster)

    params = %{
      "name" => "Cluster Name",
      "code" => "Cluster Code"
    }
    conn = put conn, cluster_path(conn, :update_edit_setup, cluster, tab: "general", cluster: params)
    assert redirected_to(conn) == cluster_path(conn, :edit, cluster, tab: "general")
  end

  test "edit_general, does not update cluster general tab with invalid attrs", %{conn: conn} do
    cluster = insert(:cluster)

    params = %{
      "name" => "",
      "code" => ""
    }
    conn = put conn, cluster_path(conn, :update_edit_setup, cluster, tab: "general", cluster: params)
    assert html_response(conn, 200) =~ "Cluster"
  end


  test "edit_account, updating cluster account tab with valid attrs", %{conn: conn} do
    cluster = insert(:cluster)
    account_group = insert(:account_group)
    insert(:account_group_cluster, account_group: account_group, cluster: cluster)
    params = %{
      "account_group_cluster_ids_main" => "#{account_group.id}"
    }
    conn = put conn, cluster_path(conn, :update_edit_setup, cluster, tab: "account", cluster: params)
    assert redirected_to(conn) == cluster_path(conn, :edit, cluster, tab: "account")
  end

  test "edit_account, does not update cluster account tab with invalid attrs", %{conn: conn} do
    insert(:account)
    cluster = insert(:cluster, code: "test")
    account_group = insert(:account_group)
    insert(:account_group_cluster, account_group: account_group, cluster: cluster)
    params = %{
      "account_group_cluster_ids_main" => ""
    }
    conn = put conn, cluster_path(conn, :update_edit_setup, cluster, tab: "account", cluster: params)
    assert html_response(conn, 200) =~ "Cluster"
  end

  describe "setup cluster" do
    test "redirect to show page when invalid params", %{conn: conn} do
      cluster = insert(:cluster, code: "test")

      conn = get conn, cluster_path(conn, :setup, cluster, id: cluster.id)
      assert redirected_to(conn) == "/clusters/#{cluster.id}"
    end

    test "redirect to index page when step is not integer and not valid", %{conn: conn} do
      cluster = insert(:cluster, code: "test")

      conn = get conn, cluster_path(conn, :setup, cluster, id: cluster.id, step: "test")
      assert redirected_to(conn) == "/clusters"
    end

    test "successfully redirect to step2", %{conn: conn} do
      cluster = insert(:cluster, code: "test")

      conn = get conn, cluster_path(conn, :setup, cluster, id: cluster.id, step: 2)
      assert html_response(conn, 200) =~ "Cluster"
    end
  end

end
