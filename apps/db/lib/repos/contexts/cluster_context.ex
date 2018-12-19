defmodule Innerpeace.Db.Base.ClusterContext do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false

  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.Cluster,
    Db.Schemas.AccountGroupCluster,
    Db.Schemas.AccountGroup,
    Db.Schemas.Account,
    Db.Schemas.ClusterLog
  }

  def list_account_group_clusters(cluster_id) do
    AccountGroupCluster
    |> where([ac], ac.cluster_id == ^cluster_id)
    |> Repo.all
    |> Repo.preload([
      account_group: [
        :payment_account,
        account: from(
          a in Account,
          where: a.status != ^"Renewal Cancelled",
          order_by: [desc: a.inserted_at]
        )
      ]
    ])
  end

  def list_all_account_group_clusters do
    AccountGroupCluster
    |> Repo.all
    |> Repo.preload([account_group: [:account, :payment_account]])
  end

  def list_cluster_accounts do
    Cluster
    |> Repo.all
    |> Repo.preload([account_group_cluster: [account_group: [:account, :payment_account]]])
  end

  def get_all_accounts do
    AccountGroup
    |> Repo.all
    |> Repo.preload([:account, :payment_account])
  end

  def set_account_group_cluster(cluster_id, account_group_ids, conn) do
    for account_group_id <- account_group_ids do
      params = %{cluster_id: cluster_id, account_group_id: account_group_id}
      changeset = AccountGroupCluster.changeset(%AccountGroupCluster{}, params)
      create_account_logs(
          cluster_id,
          conn.assigns.current_user,
          changeset,
          "Account"
      )
      Repo.insert!(changeset)
    end
  end

  def set_edit_account_group_cluster(cluster_id, account_group_ids, conn) do
    for account_group_id <- account_group_ids do
      params = %{cluster_id: cluster_id, account_group_id: account_group_id}
      changeset = AccountGroupCluster.changeset(%AccountGroupCluster{}, params)
      create_edit_account_logs(
          cluster_id,
          conn.assigns.current_user,
          changeset,
          "Account"
      )
      Repo.insert!(changeset)
    end
  end

  def get_account_count(cluster_id) do
    AccountGroupCluster
    |> where([ac], ac.cluster_id == ^cluster_id)
    |> Repo.all
    |> Enum.count
  end

  def get_cluster(id) do
    Cluster
    |> Repo.get(id)
    |> Repo.preload([
      :account_group_cluster, :cluster_log
    ])
  end

  def get_account_group_cluster(id) do
    AccountGroupCluster
    |> Repo.get!(id)
    |> Repo.preload([account_group: [:account, :payment_account]])
  end

  def get_selected_account(account_group_id) do
    AccountGroup
    |> where([ag], ag.id == ^account_group_id)
    |> Repo.all
    |> Repo.preload([:account, :payment_account])
  end

  def get_selected_account_version(account_group_id, account_id) do
    AccountGroup
    |> Repo.get!(account_group_id)
    |> Repo.preload([
      :payment_account,
      account: from(
        a in Account,
        where: a.status != ^"Renewal Cancelled",
        order_by: [desc: a.inserted_at],
        limit: 1
      )
    ])
  end

  def get_selected_account_group(account_id) do
    AccountGroup
    |> where([ag], ag.account_id == ^account_id)
    |> Repo.all
    |> Repo.preload([:account, :payment_account])
  end

  def set_account_group_cluster(cluster_id, account_group_ids) do
    for account_group_id <- account_group_ids do
      params = %{cluster_id: cluster_id, account_group_id: account_group_id}
      changeset = AccountGroupCluster.changeset(%AccountGroupCluster{}, params)
      Repo.insert!(changeset)
    end
  end

  def list_cluster!(id), do: Repo.get!(Cluster, id)
  def get_all_group_accounts(account_id) do
    Account
    |> Repo.get(account_id)
    |> Repo.preload([:account_group])
  end

  def create_cluster(attrs \\ %{}) do
    %Cluster{}
    |> Cluster.changeset(attrs)
    |> Repo.insert()
  end

  def update_cluster(%Cluster{} = cluster, attrs) do
    cluster
    |> Cluster.changeset(attrs)
    |> Repo.update()
  end

  def update_account_group_cluster(id, cluster_param) do
    id
    |> get_cluster()
    |> Cluster.changeset(cluster_param)
    |> Repo.update
  end

   def update_accounts(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  def update_cluster_step(%Cluster{} = cluster, attrs) do
    cluster
    |> Cluster.changeset_step(attrs)
    |> Repo.update()
  end

  def clear_account_group_cluster(cluster_id) do
    AccountGroupCluster
    |> where([ac], ac.cluster_id == ^cluster_id)
    |> Repo.delete_all()
  end

  def clear_cluster_logs(cluster_id) do
    ClusterLog
    |> where([ac], ac.cluster_id == ^cluster_id)
    |> Repo.delete_all()
  end

  def delete_cluster(id) do
    id
    |> get_cluster()
    |> Repo.delete()
  end

  def delete_a_account_group_cluster(id) do
    id
    |> get_account_group_cluster()
    |> Repo.delete()
  end

  def change_cluster(%Cluster{} = cluster) do
    Cluster.changeset(cluster, %{})
  end

  def change_account_group_cluster(%AccountGroupCluster{} = accountcluster) do
    AccountGroupCluster.changeset(accountcluster, %{})
  end

  def update_an_account(%Account{} = account, attrs) do
    account
    |> Account.changeset_account(attrs)
    |> Repo.update()
  end

  def extend_an_account(%Account{} = account, attrs) do
    account
    |> Account.changeset_extend_account(attrs)
    |> Repo.update()
  end

  def suspend_an_account(%Account{} = account, attrs) do
    account
    |> Account.changeset_suspend_account(attrs)
    |> Repo.update()
  end

  def cancel_an_account(%Account{} = account, attrs) do
    account
    |> Account.changeset_cancel_account_cluster(attrs)
    |> Repo.update()
  end

  def select_all_cluster_code do
    Cluster
    |> select([:code])
    |> Repo.all
  end

  def select_all_cluster_name do
    Cluster
    |> select([:name])
    |> Repo.all
  end

  def create_cluster_edit_log(user, changeset, tab) do
    if Enum.empty?(changeset.changes) == false do
      changes = changes_to_string(changeset)
      message = "#{user.username} edited #{changes} in #{tab} tab."
      insert_log(%{
        cluster_id: changeset.data.id,
        user_id: user.id,
        message: message
      })
    end
  end

  def create_cluster_logs(cluster, user, params, step) do
      changes = insert_changes_to_string_cluster(params)
      message = "#{user.username} created this cluster where #{changes} in #{step} step."
      insert_log(%{
        cluster_id: cluster.id,
        user_id: user.id,
        message: message
      })
  end

  def create_account_logs(cluster, user, params, step) do
      changes = insert_account_changes_to_string_cluster(params)
      message = "#{user.username} added an account where #{changes} in #{step} step."
      insert_log(%{
        cluster_id: cluster,
        user_id: user.id,
        message: message
      })
  end

  def create_edit_account_logs(cluster, user, params, tab) do
      changes = insert_account_changes_to_string_cluster(params)
      message = "#{user.username} change account list where #{changes} in #{tab} tab."
      insert_log(%{
        cluster_id: cluster,
        user_id: user.id,
        message: message
      })
  end

  def delete_account_logs(cluster, user, params, step) do
      changes = delete_account_changes_to_string(params)
      message = "#{user.username} removed an account where #{changes} in #{step} step."
      insert_log(%{
        cluster_id: cluster,
        user_id: user.id,
        message: message
      })
  end

  def delete_edit_account_logs(cluster, user, params, tab) do
      changes = delete_account_changes_to_string(params)
      message = "#{user.username} removed an account where #{changes} in #{tab} tab."
      insert_log(%{
        cluster_id: cluster,
        user_id: user.id,
        message: message
      })
  end

  def delete_account_changes_to_string(params) do
    changes = params
    changes = for {key, new_value} <- params, into: [] do
      "#{transform_atom(key)} is #{new_value}"
    end
    changes |> Enum.join(", ")
  end

  def insert_changes_to_string_cluster(params) do
    changes = params
    changes =
      changes
      |> Map.delete("created_by")
      |> Map.delete("updated_by")
      |> Map.delete("step")
    params = %{cluster_code: changes["code"], cluster_name: changes["name"]}
    changes = for {key, new_value} <- params, into: [] do
      "#{transform_atom(key)} is #{new_value}"
    end
    changes |> Enum.join(", ")
  end

  def insert_account_changes_to_string_cluster(params) do

    account_groups = get_selected_account(params.changes.account_group_id)
    changes = params.changes
    changes =
      changes
      |> Map.delete(:account_group_id)
      |> Map.delete(:cluster_id)
    changes =
      changes
      |> Map.merge(%{
        account_name: Enum.at(account_groups, 0).name,
        account_code: Enum.at(account_groups, 0).code,
        account_type: Enum.at(account_groups, 0).type
      })

    changes = for {key, new_value} <- changes, into: [] do
      "#{transform_atom(key)} is #{new_value}"
    end
    changes |> Enum.join(", ")
  end

  def changes_to_string(changeset) do
    changes = for {key, new_value} <- changeset.changes, into: [] do
      "Cluster #{transform_atom(key)} from #{Map.get(changeset.data, key)} to #{new_value}"
    end
    changes |> Enum.join(", ")
  end

  defp transform_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&(String.capitalize(&1)))
    |> Enum.join(" ")
  end

  defp insert_log(params) do
    changeset = ClusterLog.changeset(%ClusterLog{}, params)
    Repo.insert!(changeset)
  end

  def get_cluster_log(cluster_id, message) do
    ClusterLog
    |> where([cl], cl.cluster_id == ^cluster_id and like(cl.message, ^"%#{message}%"))
    |> order_by(desc: :inserted_at)
    |> Repo.all
  end

  def get_all_cluster_log(cluster_id) do
    ClusterLog
    |> where([cl], cl.cluster_id == ^cluster_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all
  end

end
