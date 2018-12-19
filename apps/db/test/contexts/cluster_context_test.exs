defmodule Innerpeace.Db.Base.ClusterContextTest do
  use Innerpeace.Db.SchemaCase
  use Innerpeace.Db.PayorRepo, :context

  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.Cluster,
    Db.Schemas.Account,
    # Db.Schemas.AccountGroupCluster,
    # Db.Schemas.AccountGroup,
    Db.Base.ClusterContext
  }

  # @invalid_attrs %{}

  test "list_account_group_clusters* returns all account_group_clusters by clusters" do
    account_group = insert(:account_group)
    insert(:account)
    insert(:payment_account, account_group: account_group)
    cluster = insert(:cluster)
    account_group_cluster = insert(:account_group_cluster, account_group: account_group, cluster: cluster)

    left =
      cluster.id
      |> list_account_group_clusters
      |> Repo.preload([:cluster])

    right =
      account_group_cluster
      |> Repo.preload([account_group: [:account, :payment_account]])
      |> List.wrap

    assert left == right
  end

  test "list_all_account_group_clusters* returns all account_group_clusters" do
    account_group = insert(:account_group)
    insert(:account)
    insert(:payment_account, account_group: account_group)
    cluster = insert(:cluster)
    account_group_cluster = insert(:account_group_cluster, account_group: account_group, cluster: cluster)

    left =
      ClusterContext.list_all_account_group_clusters
      |> Repo.preload([:cluster])

    right =
      account_group_cluster
      |> Repo.preload([account_group: [:account, :payment_account]])
      |> List.wrap

    assert left == right
  end

  test "list_cluster_accounts*" do
    account_group = insert(:account_group)
    insert(:account, step: "1")
    insert(:payment_account, account_group: account_group)
    cluster = insert(:cluster)
    insert(:account_group_cluster, account_group: account_group, cluster: cluster)

    left =
      ClusterContext.list_cluster_accounts

    right =
      cluster
      |> Repo.preload(account_group_cluster: [account_group: [:account, :payment_account]])
      |> List.wrap

    assert left == right
  end

  test "get_all_accounts*" do
    account_group = insert(:account_group)
    insert(:account)
    insert(:payment_account, account_group: account_group)

    left =
      ClusterContext.get_all_accounts

    right =
      account_group
      |> Repo.preload([:account, :payment_account])
      |> List.wrap
    assert left == right
  end

  test "get_account_count* test" do
    account_group = insert(:account_group)
    cluster = insert(:cluster)
    insert(:account_group_cluster, account_group: account_group, cluster: cluster)

    assert get_account_count(cluster.id) == 1
  end

  test "get_cluster* test" do
    cluster = insert(:cluster)
    insert(:account_group_cluster)
    left =
      cluster.id
      |> get_cluster
    right =
      cluster
      |> Repo.preload([:account_group_cluster, :cluster_log])

    assert left == right
  end

  test "set_account_group_cluster* sets account of the given cluster" do
    cluster = insert(:cluster)
    account_group = insert(:account_group)
    insert(:account_group_cluster)
    ClusterContext.set_account_group_cluster(cluster.id, [account_group.id])
    refute Enum.empty?(ClusterContext.get_cluster(cluster.id).account_group_cluster)
  end

  test "list_cluster* returns the cluster with given id" do
    cluster = insert(:cluster)
    assert list_cluster!(cluster.id) == cluster
  end

  test "create_cluster* with valid data creates a cluster" do
    params = %{
      name: "ClusterName1",
      code: "ClusterCode1",
      step: 1
    }
    assert {:ok, %Cluster{}} = create_cluster(params)
  end

  test "update_cluster* with valid data updates the cluster" do
    cluster = insert(:cluster)
    params = %{
      name: "ClusterName1",
      code: "ClusterCode1",
      step: 1
    }
    assert {:ok, %Cluster{}} = update_cluster(cluster, params)
  end

  test "update_account_group_cluster* with valid data updates the cluster" do
    cluster = insert(:cluster)
    params = %{
      name: "ClusterName1",
      code: "ClusterCode1",
      step: 1
    }
    assert {:ok, %Cluster{}} = update_account_group_cluster(cluster.id, params)
  end

  test "update_cluster_step* with valid data updates the cluster step" do
    cluster = insert(:cluster)
    params = %{
      name: "ClusterName1",
      code: "ClusterCode1",
      step: 3
    }
    assert {:ok, %Cluster{}} = update_cluster(cluster, params)
  end

  test "clear_account_group_cluster* deletes all accounts of the given cluster" do
    cluster = insert(:cluster)
    insert(:account_group)
    insert(:account_group_cluster)
    ClusterContext.clear_account_group_cluster(cluster.id)
    assert Enum.empty?(ClusterContext.get_cluster(cluster.id).account_group_cluster)
  end

  test "delete cluster* deletes the cluster" do
    cluster = insert(:cluster)
    assert {:ok, %Cluster{}} = ClusterContext.delete_cluster(cluster.id)
    # assert_raise Ecto.NoResultsError, fn -> ClusterContext.get_cluster(cluster.id) end
  end

  test "change_cluster* returns a cluster changeset" do
    cluster = insert(:cluster, name: "name")
    assert %Ecto.Changeset{} = change_cluster(cluster)
  end

  test "change_account_group_cluster* returns a account_group_cluster changeset" do
    account_group_cluster = insert(:account_group_cluster)
    assert %Ecto.Changeset{} = change_account_group_cluster(account_group_cluster)
  end

 test "suspend_an_account* with valid data updates the account" do
    account = insert(:account)
    params = %{
      status: "Suspended",
      suspend_date: "2017-08-09",
      suspend_remarks: "Remarks",
      suspend_reason: "others"
    }
    assert {:ok, %Account{}} = suspend_an_account(account, params)
  end

  test "extend_an_account* with valid data" do
    account = insert(:account)
    params = %{end_date: "2017-09-01"}
    assert {:ok, %Account{}} = extend_an_account(account, params)
  end
end
