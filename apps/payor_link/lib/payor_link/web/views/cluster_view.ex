defmodule Innerpeace.PayorLink.Web.ClusterView do
  use Innerpeace.PayorLink.Web, :view
  alias Innerpeace.Db.Base.ClusterContext
  alias Innerpeace.Db.Base.UserContext
  alias Innerpeace.Db.Base.Api.UtilityContext

  def check_account_clusters(account_group_clusters, account_group_id) do
    list = [] ++ for account_group_cluster <- account_group_clusters do
      account_group_cluster.account_group.id
    end
    Enum.member?(list, account_group_id)
  end

  def check_account_group_exist(all_account_groups, account_groups, cluster_id) do
    list = [] ++ for test <- Enum.reject(all_account_groups, &(&1.cluster_id == cluster_id)) do
      test.account_group
    end
    account_groups -- list
  end

  def get_all_account_group(account_groups, account_group_clusters) do
    list = [] ++ for account_group <- account_groups do
      account_group.id
    end

    list2 = [] ++ for account_group_cluster <- account_group_clusters do
      account_group_cluster.account_group.id
    end

    _list3 = list -- list2
  end

  def load_account_group(account_groups, account_group_id) do
    list = [] ++ for account_group <- account_groups do
      if account_group.id == account_group_id do
        account_group
      end
    end
    _list =
    list
    |> List.flatten()
    |> Enum.uniq()
    |> List.delete(nil)
  end

  def count_accounts(cluster_id) do
  	ClusterContext.get_account_count(cluster_id)
  end

  def get_user_by_id(created_by) do
    user = UserContext.get_user!(created_by)
    _user = user.username
  end

  def sanitize_log_message(value) do
    UtilityContext.sanitize_value(value)
  end
end
