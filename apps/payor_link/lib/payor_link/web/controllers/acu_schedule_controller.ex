defmodule Innerpeace.PayorLink.Web.AcuScheduleController do
  use Innerpeace.PayorLink.Web, :controller

  alias Elixlsx.Sheet
  alias Elixlsx.Workbook
  alias Innerpeace.Db.Schemas.Application
  alias Innerpeace.Db.{
    Base.AcuScheduleContext,
    Base.UserContext,
    Base.AccountContext,
    Base.ClusterContext,
    Base.MemberContext,
    Base.Api.UtilityContext,
    Schemas.AcuSchedule,
    Base.CoverageContext
  }

  plug :valid_uuid?, %{origin: "acu_schedules"}
  when not action in [:index]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{acu_schedules: [:manage_acu_schedules]},
       %{acu_schedules: [:access_acu_schedules]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{acu_schedules: [:manage_acu_schedules]},
     ]] when not action in [
       :index,
       :show
     ]


  def index(conn, _params) do
    pem = conn.private.guardian_default_claims["pem"]["acu_schedules"]
    users = UserContext.list_users()
    acu_schedules = AcuScheduleContext.get_all_acu_schedules_index()
    changeset = AcuSchedule.changeset(%AcuSchedule{})

    render(
      conn, "index.html",
      users: users,
      changeset: changeset,
      acu_schedules: acu_schedules,
      permission: pem
    )
  end

  def acu_schedule(conn, %{"id" => id}) do
    acu_schedule = AcuScheduleContext.get_acu_schedule(id)
    render(conn, "acu_schedule_modal.html", acu_schedule: acu_schedule)
  end

  def create_acu_schedule(conn, %{"acu_schedule" => params}) do
    params =
      params
      |> Map.put("date_from", UtilityContext.transform_string_dates(params["date_from"]))
      |> Map.put("date_to", UtilityContext.transform_string_dates(params["date_to"]))

    changeset = AcuSchedule.changeset(%AcuSchedule{})
    account_groups = AcuScheduleContext.list_active_accounts_acu()
    clusters = ClusterContext.list_cluster_accounts()
    user = conn.assigns.current_user
    product_code = params["product_code"]
    account_group = params["account_code"]
    params = Map.put(params, "status", "Draft")
    with {:ok, acu_schedule} <- AcuScheduleContext.create_acu_schedule(params, user.id),
         {:ok, acu_products} <- AcuScheduleContext.create_acu_schedule_product(acu_schedule.id, params["product_code"])
    do
      acu_schedule = AcuScheduleContext.get_acu_schedule(acu_schedule.id)

      members = AcuScheduleContext.create_acu_schedule_member(
        acu_schedule.id,
        product_code,
        account_group
      )

      #Enum.into(members, [], &(
      #  # Exq
      #  # |> Exq.enqueue(
      #  #   "acu_schedule_member_job",
      #  #   "Innerpeace.Db.Worker.Job.AcuScheduleMemberJob",
      #  #   [&1.id, acu_schedule.id, user.id]
      #  AcuScheduleContext.bgworker(&1.id, acu_schedule.id, user.id)
      #))

      AcuScheduleContext.create_acu_schedule_members_batch(members, acu_schedule)

      conn
      |> redirect(to: "/acu_schedules/#{acu_schedule.id}/edit")
    else
      {:account_not_found} ->
        conn
        |> put_flash(:error, "Error creating ACU Schedule. Account not found")
        |> render("new.html", changeset: changeset, account_groups: account_groups,
                  acu_schedule_members: [], asm_removes: [], clusters: clusters)
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error creating ACU Schedule.")
        |> render("new.html", changeset: changeset, account_groups: account_groups,
                  acu_schedule_members: [], asm_removes: [], clusters: clusters)
      _ ->
      conn
      |> put_flash(:error, "Error creating ACU Schedule.")
      |> redirect(to: "/acu_schedules/new")
    end
  end

  def step1(conn, %{"id" => id}) do
    acu_schedule = AcuScheduleContext.get_acu_schedule(id)
    if is_nil(acu_schedule) do
      conn
      |> put_flash(:error, "ACU Schedule not found")
      |> redirect(to: "/acu_schedules")
    else
      render(conn, "step1.html", acu_schedule: acu_schedule)
    end
  end

  def submit_acu_schedule_member(conn, params) do
    id = params["id"]
    asm = AcuScheduleContext. get_all_acu_schedule_member_ids(id)
    acu_schedule = AcuScheduleContext.get_acu_schedule(id)
    if is_nil(acu_schedule) do
      conn
      |> put_flash(:error, "ACU Schedule not found")
      |> redirect(to: "/acu_schedules")
    else
      if not Enum.empty?(asm) do
        if !Enum.empty?(acu_schedule.acu_schedule_packages) do
          AcuScheduleContext.delete_all_as_packages(acu_schedule.id)
        end
        insert_package_by_products_and_facility(acu_schedule.id)
        # AcuScheduleContext.update_acu_schedule_member(acu_schedule.id, asm)
        AcuScheduleContext.update_acu_schedule_status(acu_schedule, "Draft2")
        conn
        |> redirect(to: "/acu_schedules/#{acu_schedule.id}/packages")
      else
        conn
        |> put_flash(:error, "Please select at least one member.")
        |> redirect(to: "/acu_schedules/#{acu_schedule.id}/edit")
      end
    end
  end

  defp insert_package_by_products_and_facility(id) do
    acu_schedule = AcuScheduleContext.get_acu_schedule(id)
    product_codes = Enum.map(acu_schedule.acu_schedule_products, &(&1.product.code))
    member_ids = Enum.map(acu_schedule.acu_schedule_members, &(if is_nil(&1.status), do: &1.member.id))
    packages = AcuScheduleContext.get_package_by_products_and_facility(product_codes, acu_schedule.facility_id, member_ids)
    for package <- packages do
      asproduct =
        package
        |> Enum.at(3)
        |> AcuScheduleContext.get_acu_schedule_product_by_product_id()
        |> Enum.at(0)
      params = %{
        acu_schedule_id: acu_schedule.id,
        package_id: Enum.at(package, 0),
        rate: Enum.at(package, 1),
        facility_id: Enum.at(package, 2),
        acu_schedule_product_id: asproduct.id
      }
      AcuScheduleContext.insert_acu_schedule_packages(params)
    end
  end

  def check_rate(rate) do
    if is_nil(rate) do
      Decimal.new(0)
    else
      rate
    end
  end


  def render_acu_schedule_packages(conn, %{"id" => id}) do
    acu_schedule = AcuScheduleContext.get_acu_schedule(id)
    acu_schedule = check_rate(acu_schedule)
    if is_nil(acu_schedule) do
      conn
      |> put_flash(:error, "ACU Schedule not found")
      |> redirect(to: "/acu_schedules")
    else
      if acu_schedule.status == "Draft2" do
        changeset = AcuSchedule.changeset(%AcuSchedule{})
        render(conn, "acu_schedule_package.html", acu_schedule: acu_schedule, changeset: changeset)
      else
        conn
        |> redirect(to: "/acu_schedules/#{acu_schedule.id}")
      end
    end
  end

  def create_acu_schedule_loa(conn, %{"id" => id, "acu_schedule" => params}) do
    user = conn.assigns.current_user
    acu_schedule = AcuScheduleContext.get_acu_schedule(id)
    if is_nil(acu_schedule) do
      conn
      |> put_flash(:error, "ACU Schedule not found")
      |> redirect(to: "/acu_schedules")
    else
      {:ok, acu_schedule} = AcuScheduleContext.update_selected_members(acu_schedule, params["no_of_selected_members"])
      params = AcuScheduleContext.acu_schedule_api_params(acu_schedule)
      AcuScheduleContext.create_acu_schedule_api(user.id, params)

      with {:ok, token} <- AcuScheduleContext.providerlink_sign_in_v2() do
        bgworker_insert_loa(acu_schedule, user.id, token)
        AcuScheduleContext.update_acu_schedule_status(acu_schedule, "Completed")
        conn
        |> put_flash(:info, "ACU Schedule successfully created.")
        |> redirect(to: "/acu_schedules")
      else
        {:error, response} ->
          conn
          |> put_flash(:error, response)
          |> redirect(to: "/acu_schedules/#{acu_schedule.id}/packages")
        _ ->
          conn
          |> put_flash(:error, "Unable to login in providerlink")
          |> redirect(to: "/acu_schedules/#{acu_schedule.id}/packages")
      end
    end
  end

  defp bgworker_insert_loa(acu_schedule, user_id, token) do
    coverage = CoverageContext.get_coverage_by_code("ACU")
    Exq.Enqueuer.start_link
    acu_schedule.acu_schedule_members
    |> Enum.reject(&(&1.status == "removed"))
    |> Enum.each(&(
      Exq.Enqueuer.enqueue(
        Exq.Enqueuer,
        "acu_schedule_member_job",
        "Innerpeace.Worker.Job.AcuScheduleMemberJob",
        [acu_schedule.id, &1.member_id, user_id, token, coverage.id]))
    )
  end

  def update_acu_package_rate(conn, params) do
    case AcuScheduleContext.update_acu_schedule_package_rate(params) do
      {:ok, acu_schedule_package} ->
        json(conn, Poison.encode!(%{response: true}))
      {:error, changeset} ->
        json(conn, Poison.encode!(%{response: "Error in changeset"}))
    end
  end

  def get_acu_product(conn, %{"account_code" => account_code}) do
    acu_products = AcuScheduleContext.get_acu_products_by_account_code(account_code)
    json(conn, Poison.encode!(acu_products))
  end

  def get_edit_acu_schedule_product(conn, %{"account_code" => account_code, "acu_schedule_id" => id}) do
    acu_products = AcuScheduleContext.get_all_acu_schedule_products_edit(id)
    json(conn, Poison.encode!(acu_products))
  end

  def get_acu_facilities(conn, %{"params" => params}) do
    facilities = AcuScheduleContext.get_acu_facilities(params["product_code"])
    json(conn, Poison.encode!(facilities))
  end

  def get_acu_facilities(conn, %{}) do
    facilities = []
    json(conn, Poison.encode!(facilities))
  end

  def number_of_members(conn, %{"params" => params}) do
    if params["facility_id"] == "" do
      json(conn, Poison.encode!(0))
    else
      members = AcuScheduleContext.get_active_members_by_type(
        params["facility_id"],
        params["member_type"],
        params["product_code"],
        params["account_code"]
      )
      members = Enum.count(members)
      json(conn, Poison.encode!(members))
    end
  end

  # def acu_schedule_download(conn, %{"ids" => ids}) do
  #   result = AcuScheduleContext.generate_xlsx(ids, [])
  #   conn
  #   |> json(result)
  # end

  # def delete_xlsx(conn, %{"files" => files}) do
  #   path = Path.expand('./export')
  #   path =
  #     path
  #     |> String.split("/export")
  #     |> List.first()

  #   for file <- files do
  #     folder =
  #       file
  #       |> String.split("/")
  #     File.rm_rf("#{path}/#{file}")
  #   end
  #   conn
  #   |> json(%{status: true})
  # end


  def show(conn, %{"id" => id}) do
    case AcuScheduleContext.get_acu_schedule(id) do
      %AcuSchedule{} ->
        acu_schedule = AcuScheduleContext.get_acu_schedule(id)
        changeset = AcuSchedule.changeset(acu_schedule)
        account_groups = AcuScheduleContext.list_active_accounts_acu()
        clusters = ClusterContext.list_cluster_accounts()
        members = AcuScheduleContext.get_all_asm_members_for_modal("", 0, acu_schedule.id)
        # asm_removes = AcuScheduleContext.get_all_removed_asm_members_for_modal("", 0, acu_schedule.id)
        packages = AcuScheduleContext.get_all_acu_schedule_packages(acu_schedule.id)
        render(
          conn, "show.html",
          changeset: changeset,
          account_groups: account_groups,
          clusters: clusters,
          acu_schedule_members: [],
          # asm_removes: asm_removes,
          acu_schedule_packages: packages
        )
      _ ->
        conn
        |> put_flash(:error, "ACU Schedule not Found")
        |> redirect(to: acu_schedule_path(conn, :index))
    end
  end

  def get_account_date(conn, %{"account_code" => account_code}) do
    account = AccountContext.get_acu_schedule_account_by_code(account_code)
    render(conn, Innerpeace.PayorLink.Web.AcuScheduleView, "account.json", account: account)
  end

  def acu_schedule_export(conn, params) do
    params = params["acu_data"]
    params = Poison.decode!(params)
    id = params["id"]
    datetime = params["datetime"]
    acu_schedule = AcuScheduleContext.get_acu_schedule_v2(id)
    with {:ok, file} <- AcuScheduleContext.acu_schedule_export(id, datetime) do
      {file_name, binary} = file

      conn
      |> put_resp_content_type("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
      |> put_resp_header("content-disposition", "inline; filename=#{file_name}")
      |> send_resp(200, binary)
    else
      _ ->
        json(conn, %{status: "failed"})
    end
  end

  def new(conn, _params) do
    changeset = AcuSchedule.changeset(%AcuSchedule{})
    account_groups = AcuScheduleContext.list_active_accounts_acu()
    clusters = ClusterContext.list_cluster_accounts()
    #acu_schedule_members = AcuScheduleContext.get_all_acu_schedule_members(acu_schedule_id)
    render(
      conn, "new.html",
      changeset: changeset,
      account_groups: account_groups,
      clusters: clusters,
      acu_schedule_members: [],
      asm_removes: []
    )
  end

  def edit(conn, %{"id" => id}) do
    acu_schedule = AcuScheduleContext.get_acu_schedule(id)
    if is_nil(acu_schedule) do
      conn
      |> put_flash(:error, "ACU Schedule not found")
      |> redirect(to: "/acu_schedules")
    else
      removed = Enum.count(acu_schedule.acu_schedule_members, &(&1.status == "removed"))
      if is_nil(acu_schedule.status) or acu_schedule.status == "Draft" or acu_schedule.status == "Draft2"  do
      changeset = AcuSchedule.changeset(acu_schedule)
      account_groups = AcuScheduleContext.list_active_accounts_acu()
      clusters = ClusterContext.list_cluster_accounts()
      members = AcuScheduleContext.get_all_asm_members_for_modal("", 0, acu_schedule.id)
      asm_removes = AcuScheduleContext.get_all_removed_asm_members_for_modal("", 0, acu_schedule.id)
      render(
        conn, "edit.html",
        changeset: changeset,
        account_groups: account_groups,
        clusters: clusters,
        acu_schedule_members: [],
        asm_removes: asm_removes,
        removed: removed)
        else
          conn
          |> redirect(to: "/acu_schedules/#{acu_schedule.id}/packages")
        end
    end
  end

  def get_account_cluster(conn, %{"cluster_id" => cluster_id}) do
    account_group_clusters = ClusterContext.list_account_group_clusters(cluster_id)
    render(
      conn,
      Innerpeace.PayorLink.Web.AcuScheduleView,
      "account_group_cluster.json",
      account_group_clusters: account_group_clusters
    )
  end

  def update_asm_status(conn, params) do
    # as == acu_schedule
    asm_id = params["asm"]["asm_id"]
    as_id = params["asm"]["as_id"]
    AcuScheduleContext.update_removed_asm_status([asm_id])
    conn
    |> redirect(to: "/acu_schedules/#{as_id}/edit")
  end

  def update_multiple_asm_status(conn, params) do
    asm_ids = params["asm"]["asm_ids"]
    as_id = params["asm"]["as_id"]

    if asm_ids != "" do
      asm_ids = String.split(asm_ids, ",")
      AcuScheduleContext.update_asm_status(asm_ids, nil)
      conn
      |> redirect(to: "/acu_schedules/#{as_id}/edit")
    else
      conn
      |> put_flash(:error, "Please select at least one member.")
      |> redirect(to: "/acu_schedules/#{as_id}/edit")
    end
  end

  def update_acu_schedule(conn, %{"id" => id,  "acu_schedule" => params}) do
    params =
      params
      |> Map.put("date_from", UtilityContext.transform_string_dates(params["date_from"]))
      |> Map.put("date_to", UtilityContext.transform_string_dates(params["date_to"]))
    acu_schedule = AcuScheduleContext.get_acu_schedule(id)
    update_acu_schedule_2(conn, acu_schedule, params)
  end

  defp update_acu_schedule_2(conn, nil, params) do
    conn
    |> put_flash(:error, "ACU Schedule not found")
    |> redirect(to: "/acu_schedules")
  end

  defp update_acu_schedule_2(conn, acu_schedule, params) do
    account_groups = AcuScheduleContext.list_active_accounts_acu()
    clusters = ClusterContext.list_cluster_accounts()
    user = conn.assigns.current_user
    product_code = params["product_code"]
    asm_removes = AcuScheduleContext.get_all_removed_asm_members_for_modal("", 0, acu_schedule.id)
    members = AcuScheduleContext.get_all_asm_members_for_modal("", 0, acu_schedule.id)
    account_group = params["account_code"]

    AcuScheduleContext.delete_all_as_products(acu_schedule.id)
    AcuScheduleContext.delete_all_as_members(acu_schedule.id)

    with {:ok, acu_schedule} <- AcuScheduleContext.update_acu_schedule(acu_schedule, params, user.id),
         {:ok, acu_schedule_products} <- AcuScheduleContext.create_acu_schedule_product(acu_schedule.id, params["product_code"])
    do
      members = AcuScheduleContext.create_acu_schedule_member(
        acu_schedule.id,
        product_code,
        account_group
      )

      AcuScheduleContext.create_acu_schedule_members_batch(members, acu_schedule)

      conn
      |> redirect(to: "/acu_schedules/#{acu_schedule.id}/edit")
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error creating ACU Schedule.")
        |> render("new.html", changeset: changeset, account_groups: account_groups,
                  acu_schedule_members: members, clusters: clusters, asm_removes: asm_removes)
                  AcuScheduleContext.delete_acu_schedule(acu_schedule.id)
      _ ->
        conn
        |> put_flash(:error, "Error creating ACU Schedule.")
        |> redirect(to: "/acu_schedules/new")
        AcuScheduleContext.delete_acu_schedule(acu_schedule.id)
    end
  end

  def delete_acu_schedule(conn, %{"id" => acu_schedule_id}) do
    AcuScheduleContext.delete_all_as_products(acu_schedule_id)
    AcuScheduleContext.delete_all_as_members(acu_schedule_id)
    AcuScheduleContext.delete_all_as_packages(acu_schedule_id)
    AcuScheduleContext.delete_acu_schedule(acu_schedule_id)
    conn
    |> put_flash(:info, "ACU Schedule successfully deleted")
    |> redirect(to: "/acu_schedules")
  end

  def delete_acu_schedule_members(conn, params) do
    acu_schedule_id = params["acu_schedule_member"]["acu_schedule_id"]
    member_ids = String.split(params["acu_schedule_member"]["acu_schedule_member_ids_main"], ",")
    AcuScheduleContext.delete_acu_schedule_member(acu_schedule_id, member_ids)

    conn
    |> put_flash(:info, "Members successfully deleted!")
    |> redirect(to: params["acu_schedule_member"]["link"])
  end

  def asm_member_load_datatable(conn, %{"params" => params}) do
    asm = AcuScheduleContext.get_all_removed_asm_members_for_modal(params["search"], params["offset"], params["acu_schedule_id"])
    render(conn, Innerpeace.PayorLink.Web.AcuScheduleView, "load_all_acu_schedule_members.json", acu_schedule_members: asm)
  end

  #def asm_member_load_datatable_grid(conn, %{"params" => params}) do
  #  asm = AcuScheduleContext.get_all_asm_members_for_modal(params["search"], params["offset"], params["acu_schedule_id"])
  #  render(conn, Innerpeace.PayorLink.Web.AcuScheduleView, "load_all_acu_schedule_members.json", acu_schedule_members: asm)
  #end

  def load_members_tbl(conn, params) do
    count = AcuScheduleContext.get_clean_asm_count(params["search"]["value"], params["id"])
    acu_schedule_members = AcuScheduleContext.get_clean_asm(params["start"], params["length"], params["search"]["value"], params["id"])
    conn |> json(%{data: acu_schedule_members, draw: params["draw"], recordsTotal: count, recordsFiltered: count})
  end

  def load_remove_members_tbl(conn, params) do
    count = AcuScheduleContext.get_clean_removed_asm_count(params["search"]["value"], params["id"])
    acu_schedule_members = AcuScheduleContext.get_clean_removed_asm(params["start"], params["length"], params["search"]["value"], params["id"])
    conn |> json(%{data: acu_schedule_members, draw: params["draw"], recordsTotal: count, recordsFiltered: count})
  end

  def load_members_tbl_show(conn, params) do
    count = AcuScheduleContext.get_clean_asm_count(params["search"]["value"], params["id"])
    acu_schedule_members = AcuScheduleContext.get_clean_asm_show(params["start"], params["length"], params["search"]["value"], params["id"])
    conn |> json(%{data: acu_schedule_members, draw: params["draw"], recordsTotal: count, recordsFiltered: count})
  end
end
