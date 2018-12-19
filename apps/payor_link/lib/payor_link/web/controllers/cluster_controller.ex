defmodule Innerpeace.PayorLink.Web.ClusterController do
  use Innerpeace.PayorLink.Web, :controller
  use Innerpeace.Db.PayorRepo, :context
  alias Innerpeace.PayorLink.Web.ClusterView

  # alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Base.AccountContext
  alias Innerpeace.Db.Base.Api.UtilityContext
  alias Innerpeace.Db.Schemas.{
    Cluster,
    Account,
    AccountGroupCluster,
    AccountGroup
    # ClusterLog
  }
  alias Phoenix.View

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{clusters: [:manage_clusters]},
       %{clusters: [:access_clusters]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{clusters: [:manage_clusters]},
     ]] when not action in [
       :index,
       :show
     ]

  plug :valid_uuid?, %{origin: "clusters"}
  when not action in [:index]

  def index(conn, _params) do
    clusters = list_cluster_accounts()
    render(conn, "index.html", clusters: clusters)
  end

  def new(conn, _params) do
    changeset = change_cluster(%Cluster{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"cluster" => cluster_params}) do
    cluster_params =
      cluster_params
      |> Map.put("step", 2)
      |> Map.put("created_by", conn.assigns.current_user.id)
      |> Map.put("updated_by", conn.assigns.current_user.id)

    case create_cluster(cluster_params) do
      {:ok, cluster} ->
        create_cluster_logs(
          cluster,
          conn.assigns.current_user,
          cluster_params,
          "General"
      )
        conn
        |> put_flash(:info, "Cluster created successfully.")
        |> redirect(to: "/clusters/#{cluster.id}/setup?step=2") # pass to setup
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error creating cluster! Check the errors below.")
        render(conn, "new.html", changeset: changeset)
    end
  end

  def account_movements(conn, %{"id" => id, "account_id" => account_id}) do
    cluster = get_cluster(id)
    account_group_clusters = list_account_group_clusters(cluster.id)
    account = AccountContext.get_account!(account_id)
    account_group = get_selected_account_version(account.account_group_id, account_id)
    changeset = change_cluster(%Cluster{})
    changeset_account = AccountContext.change_account(%Account{})
    render(conn,
           "account_new.html",
           account: account,
           cluster: cluster,
           changeset: changeset,
           changeset_account: changeset_account,
           account_group: account_group,
           account_group_clusters: account_group_clusters)
  end

  def update_renew(conn, %{"cluster" => cluster_params}) do
    account = get_account!(cluster_params["account_id"])

    if account.status == "Active" || account.status == "Lapsed" do
      latest = get_latest_account(account.account_group_id)
      user = conn.assigns.current_user.id
      account_params =
        account
        |> Map.take([:step, :account_group_id])
        |> Map.put(:status, "For Renewal")
        |> Map.put(:created_by, user)
        |> Map.put(:updated_by, user)
        |> Map.put(:major_version, latest.major_version + 1)
        |> Map.put(:minor_version, 0)
        |> Map.put(:build_version, 0)
        |> Map.put(:start_date, cluster_params["start_date"])
        |> Map.put(:end_date, cluster_params["end_date"])

        case create_renew_cluster(account_params) do
          {:ok, new_account} ->
            clone_account_product(account, new_account)
            conn
            |> put_flash(:info, "Account will be renewed on #{account.start_date}")
            |> redirect(to: "/clusters/#{cluster_params["cluster_id"]}/accounts/#{cluster_params["account_id"]}")
          {:error, _error} ->
            conn
            |> put_flash(:error, "Error upon renewing an account.")
            |> redirect(to: "/clusters/#{cluster_params["cluster_id"]}/accounts/#{cluster_params["account_id"]}")
        end
        else
          conn
          |> put_flash(:error, "The status of account should be active or lapsed to renew.")
          |> redirect(to: "/clusters/#{cluster_params["cluster_id"]}/accounts/#{cluster_params["account_id"]}")
    end
  end

  def update_suspend(conn, %{"cluster" => cluster_params}) do
    account = get_account!(cluster_params["account_id"])
    case suspend_an_account(account, cluster_params) do
      {:ok, _account} ->
        conn
        |> put_flash(:info, "Successfully suspend an account.")
        |> redirect(to: "/clusters/#{cluster_params["cluster_id"]}/accounts/#{cluster_params["account_id"]}")
      {:error, %Ecto.Changeset{} = _changeset} ->
        conn
        |> put_flash(:error, "Error upon suspending an account.")
        |> redirect(to: "/clusters/#{cluster_params["cluster_id"]}/accounts/#{cluster_params["account_id"]}")
    end

  end

  def setup(conn, %{"id" => id, "step" => step}) do
    if is_nil(step) do
      conn
      |> put_flash(:error, "Invalid Step")
      |> redirect(to: cluster_path(conn, :index))
    else
      cluster = get_cluster(id)
      validate_step(conn, cluster, step)
      case step do
        "1" ->
          step1(conn, cluster)
        "2" ->
          step2(conn, cluster)

        "3" ->
          step3(conn, cluster)
        _ ->
          conn
          |> put_flash(:error, "Invalid step!")
          |> redirect(to: cluster_path(conn, :index))
      end
    end

    rescue
      _ ->
        conn
        |> put_flash(:error, "Invalid Step")
        |> redirect(to: cluster_path(conn, :index))
  end

  def setup(conn, params) do
    conn
    |> put_flash(:error, "Page Not Found!")
    |> redirect(to: cluster_path(conn, :show, params["id"]))
  end

  def step2(conn, cluster) do
    changeset = AccountGroup.changeset(%AccountGroup{})
    account_groups = get_all_accounts()
    account_group_clusters = list_account_group_clusters(cluster.id)
    all_account_group_clusters = list_all_account_group_clusters()
    render(conn, "step2.html", cluster: cluster,
           changeset: changeset,
           account_groups: account_groups,
           account_group_clusters: account_group_clusters,
           all_account_group_clusters: all_account_group_clusters)
  end

  def step1(conn, cluster) do
    changeset = change_cluster(cluster)
    _account_groups = get_all_accounts()
    render(conn, "edit.html", changeset: changeset, cluster: cluster)
  end

  def step3(conn, cluster) do
    changeset = Cluster.changeset_step(cluster)
    accounts = get_all_accounts()
    account_group_clusters = list_account_group_clusters(cluster.id)
    render(
      conn,
      "step3.html",
      changeset: changeset,
      cluster: cluster,
      accounts: accounts,
      account_group_clusters: account_group_clusters
    )
  end

  def validate_step(conn, cluster, step) do
    if cluster.step < String.to_integer(step) do
      conn
      |> put_flash(:error, "Not allowed!")
      |> redirect(to: cluster_path(conn, :index))
    end
  end

  def edit(conn, %{"id" => id, "tab" => tab})do
    cluster = get_cluster(id)
    case tab do
      "general" ->
        edit_general(conn, cluster)
      "account" ->
        edit_account(conn, cluster)
    end
  end

  def edit(conn, params)do
    if params["id"] != "" or is_nil(params["id"]) do
      cluster = params["id"]
      conn
      |> put_flash(:error, "Invalid tab")
      |> redirect(to: "/clusters/#{cluster}")
    else
      conn
      |> put_flash(:error, "Invalid tab!")
      |> redirect(to: cluster_path(conn, :index))
    end
  end

  def next_step3(conn, %{"id" => cluster_id}) do
    cluster = list_cluster!(cluster_id)
    if cluster.step == 2 do
      update_cluster_step(
        list_cluster!(cluster_id),
        %{step: 3}
      )
    end
    conn
    |> redirect(to: "/clusters/#{cluster_id}/setup?step=3")
  end

  def update(conn, %{"id" => id, "cluster" => cluster_params}) do
     cluster_params =
      cluster_params
      |> Map.put("step", 2)
      |> Map.put("created_by", conn.assigns.current_user.id)
      |> Map.put("updated_by", conn.assigns.current_user.id)
    cluster = get_cluster(id)
    case update_cluster(id, cluster_params) do
      {:ok, cluster} ->
        conn
        |> put_flash(:info, "Cluster Updated Successfully!")
        |> redirect(to: cluster_path(conn, :show, cluster))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", cluster: cluster, changeset: changeset)
    end
  end

  def update_setup(conn, %{"id" => id, "step" => step, "cluster" => cluster_params}) do
    cluster = get_cluster(id)
    case step do
      "1" ->
        step1_update(conn, cluster, cluster_params)
      "2" ->
        step2_update(conn, cluster, cluster_params)
      "3" ->
        step3_update(conn, cluster, cluster_params)
      _ ->
        conn
        |> put_flash(:error, "Invalid step!")
        |> redirect(to: cluster_path(conn, :index))
    end
  end

  def step1_update(conn, cluster, cluster_params) do
    cluster_params =
      cluster_params
      |> Map.put("step", 2)
      |> Map.put("created_by", conn.assigns.current_user.id)
      |> Map.put("updated_by", conn.assigns.current_user.id)
    with {:ok, _update_cluster} <- update_account_group_cluster(cluster.id, cluster_params)
    do
      clear_cluster_logs(cluster.id)
      create_cluster_logs(
          cluster,
          conn.assigns.current_user,
          cluster_params,
          "General"
      )
      conn
      |> put_flash(:info, "Cluster updated successfully.")
      |> redirect(to: "/clusters/#{cluster.id}/setup?step=2")
    else {:error, %Ecto.Changeset{} = changeset} ->
      render(conn, "edit.html", cluster: cluster, changeset: changeset)
    end
  end

  def step2_update(conn, cluster, cluster_params) do
    accounts = get_all_accounts()
    account_groups = get_all_accounts()
    account_group_clusters = list_account_group_clusters(cluster.id)
    all_account_group_clusters = list_all_account_group_clusters()
    changeset =
      %AccountGroupCluster{}
      |> AccountGroupCluster.changeset()
      |> Map.delete(:action)
      |> Map.put(:action, "insert")
    account = String.split(cluster_params["account_group_cluster_ids_main"], ",")
    if account == [""] do
      conn
      |> put_flash(:error, "At least one Account is required")
      |> render("step2.html",
          changeset: changeset,
          cluster: cluster,
          accounts: accounts,
          account_groups: account_groups,
          account_group_clusters: account_group_clusters,
          modal_open: true,
          all_account_group_clusters: all_account_group_clusters
        )
    else
      #clear_account_group_cluster(cluster.id)
      set_account_group_cluster(cluster.id, account, conn)
      update_step(conn, cluster, "3")
      conn
      |> put_flash(:info, "Account successfully added!")
      |> redirect(to: "/clusters/#{cluster.id}/setup?step=2")
    end
  end

  def step3_update(_conn, _cluster, _cluster_params) do
    raise"yeah"
  end

  # defp step4_update(conn, package, step) do
  #   update_step(conn, package, step)
  #   conn
  #   |> redirect(to: "/packages/#{package.id}?active=procedures")
  # end

  defp update_step(_conn, cluster, step) do
    update_cluster(cluster, %{"step" => step})
  end

  def show(conn, %{"id" => id}) do
    cluster = get_cluster(id)
    if is_nil(cluster) do
      conn
      |> put_flash(:error, "Page not found")
      |> redirect(to: cluster_path(conn, :index))
    else
      accounts = get_all_accounts()
      account_group_clusters = list_account_group_clusters(cluster.id)
      render(conn, "show.html", cluster: cluster,
             accounts: accounts,
             account_group_clusters: account_group_clusters)
    end
  end

  def delete(conn, %{"id" => id}) do
    {:ok, _cluster} = delete_cluster(id)
    conn
    |> put_flash(:info, "Cluster deleted successfully.")
    |> redirect(to: cluster_path(conn, :index))
  end

  def submit(conn, %{"id" => id}) do
    cluster = get_cluster(id)
    update_step(conn, cluster, 0)
    conn
    |> put_flash(:info, "Cluster successfully created!")
    |> redirect(to: "/clusters/#{cluster.id}")
  end

  def delete_account_group_clusters(conn, %{"id" => id}) do
    account_group_cluster = get_account_group_cluster(id)
    params =
      %{
        account_code: account_group_cluster.account_group.code,
        account_name: account_group_cluster.account_group.name,
        account_type: account_group_cluster.account_group.type
      }
    delete_account_logs(account_group_cluster.cluster_id, conn.assigns.current_user, params, "Account")
    {:ok, cluster} = delete_a_account_group_cluster(id)
    conn
    |> put_flash(:info, "Account deleted successfully")
    |> redirect(to: "/clusters/#{cluster.cluster_id}/setup?step=2")
  end

  def delete_edit_account_group_clusters(conn, %{"id" => id}) do
    account_group_cluster = get_account_group_cluster(id)
    params =
      %{
        account_code: account_group_cluster.account_group.code,
        account_name: account_group_cluster.account_group.name,
        account_type: account_group_cluster.account_group.type
      }
    delete_edit_account_logs(account_group_cluster.cluster_id, conn.assigns.current_user, params, "Account")
    {:ok, cluster} = delete_a_account_group_cluster(id)
    conn
    |> put_flash(:info, "Account deleted successfully")
    |> redirect(to: "/clusters/#{cluster.cluster_id}/edit?tab=account")
  end

  def get_all_group_accounts(conn, %{"account_id" => account_id}) do
    account = get_all_group_accounts(account_id)
    json conn, Poison.encode!(account)
  end

  def update_cancel(conn, %{"cluster" => cluster_params}) do
    account = get_account!(cluster_params["account_id"])
    case cancel_an_account(account, cluster_params) do
      {:ok, _account} ->
        conn
        |> put_flash(:info, "Account Cancelled Successfully.")
        |> redirect(to: "/clusters/#{cluster_params["cluster_id"]}/accounts/#{cluster_params["account_id"]}")
      {:error, %Ecto.Changeset{} = _changeset} ->
        conn
        |> put_flash(:error, "Error upon cancelling account.")
        |> redirect(to: "/clusters/#{cluster_params["cluster_id"]}/accounts/#{cluster_params["account_id"]}")
    end
  end

  # Cluster - Extend Account
def update_extend(conn, %{"cluster" => cluster_params}) do
  account = get_account!(cluster_params["account_id"])

  with {:ok, _account} <- extend_an_account(account, cluster_params)
  do
    conn
    |> put_flash(:info, "Account Extended Successfully.")
    |> redirect(to: "/clusters/#{cluster_params["cluster_id"]}/accounts/#{cluster_params["account_id"]}")
  else
    {:error, %Ecto.Changeset{} = _changeset} ->
      conn
      |> put_flash(:error, "Error upon extension of account.")
      |> redirect(to: "/clusters/#{cluster_params["cluster_id"]}/accounts/#{cluster_params["account_id"]}")
  end
end
# End Cluster - Extend Account

def load_all_clusters(conn, _params) do
  clusters = select_all_cluster_code()
  json conn, Poison.encode!(clusters)
end

def load_all_clusters_name(conn, _params) do
  clusters = select_all_cluster_name()
  json conn, Poison.encode!(clusters)
end

def update_edit_setup(conn, %{"id" => id, "tab" => tab, "cluster" => cluster_params}) do
  cluster = get_cluster(id)
  case tab do
    "general" ->
      update_edit_general(conn, cluster, cluster_params)
    "account" ->
      update_edit_account(conn, cluster, cluster_params)
  end
end

def edit_general(conn, cluster) do
  changeset = Cluster.update_general_changeset(cluster, %{})
  render(conn, "edit/general.html", cluster: cluster, changeset: changeset)
end

def edit_account(conn, cluster) do
  changeset = AccountGroup.changeset(%AccountGroup{})
  account_groups = get_all_accounts()
  account_group_clusters = list_account_group_clusters(cluster.id)
  all_account_group_clusters = list_all_account_group_clusters()
  render(conn, "edit/account.html", cluster: cluster,
         changeset: changeset,
         account_groups: account_groups,
         account_group_clusters: account_group_clusters,
         all_account_group_clusters: all_account_group_clusters)
end

def update_edit_general(conn, cluster, cluster_params) do
  cluster_params =
    cluster_params
    |> Map.put("created_by", conn.assigns.current_user.id)
    |> Map.put("updated_by", conn.assigns.current_user.id)
  case update_account_group_cluster(cluster.id, cluster_params) do
    {:ok, _update_cluster} ->

      create_cluster_edit_log(
          conn.assigns.current_user,
          Cluster.changeset(cluster, cluster_params),
          "General"
      )
      conn
      |> put_flash(:info, "Cluster updated successfully.")
      |> redirect(to: "/clusters/#{cluster.id}/edit?tab=general")
    {:error, %Ecto.Changeset{} = changeset} ->
      render(conn, "edit/general.html", cluster: cluster, changeset: changeset)
  end
end

def update_edit_account(conn, cluster, cluster_params) do
  accounts = get_all_accounts()
  account_groups = get_all_accounts()
  account_group_clusters = list_account_group_clusters(cluster.id)
  all_account_group_clusters = list_all_account_group_clusters()
  changeset =
    %AccountGroupCluster{}
    |> AccountGroupCluster.changeset()
    |> Map.delete(:action)
    |> Map.put(:action, "insert")
  account = String.split(cluster_params["account_group_cluster_ids_main"], ",")
  if account == [""] do
    conn
    |> put_flash(:error, "At least one Account is required")
    |> render("edit/account.html",
        changeset: changeset,
        cluster: cluster,
        accounts: accounts,
        account_groups: account_groups,
        account_group_clusters: account_group_clusters,
        modal_open: true,
        all_account_group_clusters: all_account_group_clusters
        )
  else
    #clear_account_group_cluster(cluster.id)
    set_edit_account_group_cluster(cluster.id, account, conn)
    update_step(conn, cluster, "3")
    conn
    |> put_flash(:info, "Successfully added!")
    |> redirect(to: "/clusters/#{cluster.id}/edit?tab=account")
  end
end

  def show_log(conn, %{"id" => id, "message" => message}) do
    cluster_logs = get_cluster_log(id, message)
    cluster_logs =
      Enum.into(cluster_logs, [],
      &(%{
        inserted_at: &1.inserted_at,
        message: UtilityContext.sanitize_value(&1.message)
      }))
    json conn, Poison.encode!(cluster_logs)
  end

  def show_all_log(conn, %{"id" => id}) do
    cluster_logs = get_all_cluster_log(id)
    cluster_logs =
      Enum.into(cluster_logs, [],
      &(%{
        inserted_at: &1.inserted_at,
        message: UtilityContext.sanitize_value(&1.message)
      }))
    json conn, Poison.encode!(cluster_logs)
  end

  def print_cluster(conn, %{"id" => cluster_id}) do
    cluster = get_cluster(cluster_id)
    accounts = get_all_accounts()
    account_group_clusters = list_account_group_clusters(cluster_id)

    html =
      View.render_to_string(
        ClusterView, "print_summary.html",
        cluster: cluster,
        accounts: accounts,
        account_group_clusters: account_group_clusters,
        conn: conn
      )

    {date, time} = :erlang.localtime
    unique_id = Enum.join(Tuple.to_list(date)) <> Enum.join(Tuple.to_list(time))
    filename = "#{cluster.code}_#{unique_id}"

    with {:ok, content} <- PdfGenerator.generate_binary html, filename: filename, delete_temporary: true
    do
      conn
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "inline; filename=#{filename}.pdf")
      |> send_resp(200, content)
     else
       {:error, _reason} ->
         conn
         |> put_flash(:error, "Failed to print cluster.")
         |> redirect(to: "/clusters/#{cluster.id}")
    end
  end

end
