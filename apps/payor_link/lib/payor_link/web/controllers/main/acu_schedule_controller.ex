defmodule Innerpeace.PayorLink.Web.Main.AcuScheduleController do
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
    Datatables.AcuScheduleDatatable,
    Schemas.AcuSchedule,
    Base.CoverageContext,
    Base.Api.UtilityContext
  }
  alias Innerpeace.PayorLink.{
    EmailSmtp,
    Mailer
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
       :show,
       :load_members_tbl_show
     ]

  def index(conn, _params) do
    acu_schedules = AcuScheduleContext.get_all_acu_schedules_index()
    changeset = AcuSchedule.changeset(%AcuSchedule{})

    render(
      conn, "index.html",
      changeset: changeset,
      acu_schedules: acu_schedules
    )
  end

  def new(conn, _params) do
    changeset = AcuSchedule.changeset(%AcuSchedule{})
    account_groups = AcuScheduleContext.list_active_accounts_acu()
    clusters = ClusterContext.list_cluster_accounts()
    render(
      conn, "new.html",
      changeset: changeset,
      account_groups: account_groups,
      clusters: clusters,
      acu_schedule_members: [],
      asm_removes: []
    )
  end

  def create_acu_schedule(conn, %{"acu_schedule" => params}) do
    changeset = AcuSchedule.changeset(%AcuSchedule{})
    account_groups = AcuScheduleContext.list_active_accounts_acu()
    clusters = ClusterContext.list_cluster_accounts()
    user = conn.assigns.current_user
    product_code = params["product_code"]
    account_group = params["account_code"]
    params = Map.put(params, "status", "Draft")
    with {:ok, acu_schedule} <- AcuScheduleContext.new_create_acu_schedule(params, user.id),
         {:ok, acu_products} <- AcuScheduleContext.create_acu_schedule_product(acu_schedule.id, params["product_code"])
    do
      acu_schedule = AcuScheduleContext.get_acu_schedule(acu_schedule.id)
      members = AcuScheduleContext.new_create_acu_schedule_member(
        acu_schedule.id,
        product_code,
        account_group
      )

      members =
        members
        |> Enum.uniq()
        |> List.delete(nil)

      AcuScheduleContext.new_create_acu_schedule_members_batch(members, acu_schedule)

      if params["save_as_draft"] == "true" do
        conn
        |> redirect(to: "/web/acu_schedules")
      else
        conn
        |> redirect(to: "/web/acu_schedules/#{acu_schedule.id}/edit")
      end
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
      |> redirect(to: "/web/acu_schedules/new")
    end
  end

  def edit(conn, %{"id" => id}) do
    acu_schedule = AcuScheduleContext.get_acu_schedule_v2(id)
    cond do
      is_nil(acu_schedule) ->
        conn
        |> put_flash(:error, "ACU Schedule not found")
        |> redirect(to: "/web/acu_schedules")
      !is_nil(acu_schedule.status) and acu_schedule.status != "Draft" ->
        conn
        |> put_flash(:error, "ACU Schedule has been finalized. Cannot be edited.")
        |> redirect(to: "/web/acu_schedules")
      true ->
        removed = Enum.count(acu_schedule.acu_schedule_members, &(&1.status == "removed"))
        changeset = AcuSchedule.changeset(acu_schedule)
        account_groups = AcuScheduleContext.list_active_accounts_acu()
        clusters = ClusterContext.list_cluster_accounts()
        members = AcuScheduleContext.new_get_all_asm_members_for_modal("", 0, acu_schedule.id)
        asm_removes = AcuScheduleContext.get_all_removed_asm_members_for_modal_v3("", 0, acu_schedule.id)
        render(
          conn, "edit.html",
          acu_schedule: acu_schedule,
          changeset: changeset,
          account_groups: account_groups,
          clusters: clusters,
          acu_schedule_members: members,
          asm_removes: asm_removes,
          removed: removed)
    end
  end

  defp insert_package_by_products_and_facility(id) do
    acu_schedule = AcuScheduleContext.get_acu_schedule(id)
    delete_acu_schedule_package(!Enum.empty?(acu_schedule.acu_schedule_packages), acu_schedule.id)
    product_codes = Enum.map(acu_schedule.acu_schedule_products, &(&1.product.code))
    package_codes = Enum.map(acu_schedule.acu_schedule_members, &(if is_nil(&1.status), do: &1.package_code))
    package_codes = package_codes |> Enum.uniq() |> List.delete(nil)
    packages = AcuScheduleContext.new_get_package_by_products_and_facility(product_codes, acu_schedule.facility_id, package_codes)

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

  defp validate_package_count(0, id), do: insert_package_by_products_and_facility(id)
  defp validate_package_count(_, _), do: ""

  def update_asm_status(conn, params) do
    with {:ok, acu_schedule} <- get_acu_schedule(AcuScheduleContext.get_acu_schedule(params["asm"]["as_id"]))
    do
      AcuScheduleContext.update_removed_asm_status([params["asm"]["asm_id"]])

      package = AcuScheduleContext.get_package_by_asm(params["asm"]["asm_id"])
      validate_package_count(
        AcuScheduleContext.get_asm_by_package_count(acu_schedule.id, package),
        acu_schedule.id
      )

      conn
      |> put_flash(:info, "ACU schedule member successfully deleted.")
      |> redirect(to: "/web/acu_schedules/#{acu_schedule.id}/edit")
    else
      _ ->
        conn
        |> put_flash(:error, "Error deleting member to ACU schedule.")
        |> redirect(to: "/web/acu_schedules")
    end
  end

  def update_multiple_asm_status(conn, params) do
    with {:ok, acu_schedule} <- get_acu_schedule(AcuScheduleContext.get_acu_schedule(params["asm"]["as_id"])),
         {:ok, asm_ids} <- validate_asm_ids(params["asm"]["asm_ids"])
    do
      AcuScheduleContext.update_asm_status(asm_ids, nil)
      validate_update_acu_schedule_packages(params["acu_schedule"]["selected_package"])
      insert_package_by_products_and_facility(acu_schedule.id)

      conn
      |> redirect(to: "/web/acu_schedules/#{acu_schedule.id}/edit")
    else
      nil ->
        conn
        |> put_flash(:error, "Please select at least one member.")
        |> redirect(to: "/web/acu_schedules/#{params["asm"]["as_id"]}/edit")
      _ ->
        conn
        |> put_flash(:error, "Error adding members to ACU schedule.")
        |> redirect(to: "/web/acu_schedules")
    end
  end

  defp get_acu_schedule(nil), do: {:invalid}
  defp get_acu_schedule(acu_schedule), do: {:ok, acu_schedule}

  defp validate_asm_ids(nil), do: nil
  defp validate_asm_ids(""), do: nil
  defp validate_asm_ids(ids) do
    ids
    |> String.split(",")
    |> Enum.map(&(
      &1
      |> String.split("||")
      |> Enum.at(0)
    ))
    |> Enum.reject(&( {:invalid_id} == UtilityContext.valid_uuid?(&1)))
    |> validate_asm_ids2()
  end

  defp validate_asm_ids2([]), do: nil
  defp validate_asm_ids2(ids), do: {:ok, ids}

  defp delete_acu_schedule_package(_, id), do: AcuScheduleContext.delete_all_as_packages(id)
  defp delete_acu_schedule_package(false, _), do: ""

  defp validate_update_acu_schedule_packages(nil), do: {:updated}
  defp validate_update_acu_schedule_packages([]), do: {:updated}
  defp validate_update_acu_schedule_packages(packages), do: update_acu_schedule_packages(packages)

  defp update_acu_schedule_packages(asm_packages) do
    packages = Enum.map(asm_packages |> Enum.uniq() |> List.delete(""), &(Enum.at(String.split(&1, ", "), 1)))
    for package <- Enum.uniq(packages) do
      asm_ids = Enum.map(asm_packages, &(if Enum.at(String.split(&1, ", "), 1) == package, do: Enum.at(String.split(&1, ", "), 0)))
        asm_ids
        |> Enum.uniq()
        |> List.delete(nil)
        |> AcuScheduleContext.update_acu_schedule_member_package(package)
    end
    {:updated}
  end

  def update_acu_schedule(conn, %{"id" => id,  "acu_schedule" => params}) do
    required_keys = ["account_code", "product_code", "facility_id", "date_from", "date_to", "time_from", "time_to", "number_of_members_val", "guaranteed_amount"]
    with acu_schedule = AcuScheduleContext.get_acu_schedule(id),
         {:ok, params} <- UtilityContext.check_valid_params(params, required_keys)
    do
      account_groups = AcuScheduleContext.list_active_accounts_acu()
      clusters = ClusterContext.list_cluster_accounts()
      user = conn.assigns.current_user
      product_code = params["product_code"]
      asm_removes = AcuScheduleContext.get_all_removed_asm_members_for_modal("", 0, acu_schedule.id)
      members = AcuScheduleContext.get_all_asm_members_for_modal("", 0, acu_schedule.id)
      account_group = params["account_code"]

      AcuScheduleContext.delete_all_as_products(acu_schedule.id)
      AcuScheduleContext.delete_all_as_packages(acu_schedule.id)
      AcuScheduleContext.delete_all_as_members(acu_schedule.id)

      with {:ok, acu_schedule} <- AcuScheduleContext.new_update_acu_schedule(acu_schedule, params, user.id),
           {:ok, acu_schedule_products} <- AcuScheduleContext.create_acu_schedule_product(acu_schedule.id, params["product_code"])
      do
        members = AcuScheduleContext.new_create_acu_schedule_member(
          acu_schedule.id,
          product_code,
          account_group
        )
        members =
          members
          |> Enum.uniq()
          |> List.delete(nil)

        AcuScheduleContext.new_create_acu_schedule_members_batch(members, acu_schedule)
        if params["save_as_draft"] == "true" do
          conn
          |> redirect(to: "/web/acu_schedules")
        else
          conn
          |> redirect(to: "/web/acu_schedules/#{acu_schedule.id}/edit")
        end
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
          |> redirect(to: "/web/acu_schedules/new")
        AcuScheduleContext.delete_acu_schedule(acu_schedule.id)
      end
    else
      {:error_params, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: "/web/acu_schedules/#{id}/edit")
      nil ->
        conn
        |> put_flash(:error, "ACU Schedule not found")
        |> redirect(to: "/web/acu_schedules")
      _ ->
        conn
        |> put_flash(:error, "Error creating ACU Schedule.")
        |> redirect(to: "/web/acu_schedules/new")
    end
  end

  def update_acu_package_rate(conn, params) do
    package_rate_params = params["acu_schedule_package"]
    case AcuScheduleContext.new_update_acu_schedule_package_rate(package_rate_params) do
      {:ok, acu_schedule_package} ->
        conn
        |> put_flash(:info, "Package rate successfully updated.")
        |> redirect(to: "/web/acu_schedules/#{package_rate_params["acu_schedule_id"]}/edit")
      {:error, changeset} ->
        conn
        |> put_flash(:info, "Error updating package rate.")
        |> redirect(to: "/web/acu_schedules/#{package_rate_params["acu_schedule_id"]}/edit")
      _ ->
        conn
        |> put_flash(:info, "Error updating package rate.")
        |> redirect(to: "/web/acu_schedules/#{package_rate_params["acu_schedule_id"]}/edit")
    end
  end

  def show(conn, %{"id" => id}) do
    with acu_schedule = %AcuSchedule{} <- AcuScheduleContext.get_acu_schedule_v2(id) do
        changeset = AcuSchedule.changeset(acu_schedule)
        account_groups = AcuScheduleContext.list_active_accounts_acu()
        clusters = ClusterContext.list_cluster_accounts()
        packages = AcuScheduleContext.get_all_acu_schedule_packages(acu_schedule.id)
        render(
          conn, "show.html",
          changeset: changeset,
          account_groups: account_groups,
          clusters: clusters,
          acu_schedule: acu_schedule,
          acu_schedule_members: [],
          # asm_removes: asm_removes,
          acu_schedule_packages: packages
        )
    else
      _ ->
        conn
        |> put_flash(:error, "ACU Schedule not Found")
        |> redirect(to: main_acu_schedule_path(conn, :index))
    end
  end

  def submit_acu_schedule_member(conn, %{"id" => id, "acu_schedule" => params}) do
    date_inserted = params["date_inserted"]
    # asm_packages = params["selected_package"]
    # if is_nil(asm_packages) || Enum.empty?(asm_packages) do
    # else
    #   packages = Enum.map(asm_packages, &(Enum.at(String.split(&1, ","), 1)))
    #   for package <- Enum.uniq(packages) do
    #     asm_ids = Enum.map(asm_packages, &(if Enum.at(String.split(&1, ","), 1) == package, do: Enum.at(String.split(&1, ","), 0)))
    #     asm_ids =
    #       asm_ids
    #       |> Enum.uniq()
    #       |> List.delete(nil)
    #     AcuScheduleContext.update_acu_schedule_member_package(package, asm_ids)
    #   end
    # end
    user = conn.assigns.current_user
    acu_schedule = AcuScheduleContext.get_acu_schedule(id)
    if is_nil(acu_schedule) do
      conn
      |> put_flash(:error, "ACU Schedule not found")
      |> redirect(to: "/web/acu_schedules")
    else
      {:ok, acu_schedule} = AcuScheduleContext.new_update_selected_members(acu_schedule, params)
      params = AcuScheduleContext.new_acu_schedule_api_params(acu_schedule)
      AcuScheduleContext.create_acu_schedule_api(user.id, params)
      # AcuScheduleContext.bgworker_loa(acu_schedule, user.id)
      with {:ok, token} <- AcuScheduleContext.providerlink_sign_in_v2() do
        # if AcuScheduleContext.if_acu_sched_notif?(user) do
        #   send_email_notification(conn, acu_schedule, date_inserted)
        # end
        bgworker_insert_loa(acu_schedule, user.id, token)
        AcuScheduleContext.new_update_acu_schedule_status(acu_schedule, "Completed")

        conn
        |> put_flash(:info, "ACU Schedule successfully created.")
        |> redirect(to: "/web/acu_schedules/#{acu_schedule.id}")
      else
        {:error, response} ->
          conn
          |> put_flash(:error, response)
          |> redirect(to: "/web/acu_schedules/#{acu_schedule.id}/edit")
        _ ->
          conn
          |> put_flash(:error, "Unable to login in providerlink")
          |> redirect(to: "/web/acu_schedules/#{acu_schedule.id}/edit")
      end
    end
  end

  defp bgworker_insert_loa(acu_schedule, user_id, token) do
    asm_count = acu_schedule_members_count(acu_schedule) |> Enum.count()
    {_, job_acu_sched} = AcuScheduleContext.job_acu_schedule_params(user_id, acu_schedule.id, asm_count)
                    |> AcuScheduleContext.insert_job_acu_schedule()

    coverage = CoverageContext.get_coverage_by_code("ACU")
    Exq.Enqueuer.start_link
    asm =
    acu_schedule_members_count(acu_schedule)
    |> Enum.each(fn(asm) ->
    {_, task_acu_sched} =
      user_id
      |> map_request(asm.member_id, acu_schedule.id, token, coverage.id)
      |> insert_task_acu_schedule(job_acu_sched.id, user_id)

      Exq.Enqueuer.enqueue(
        Exq.Enqueuer,
        "acu_schedule_member_job",
        "Innerpeace.Worker.Job.AcuScheduleMemberJob",
        [acu_schedule.id, asm.member_id, user_id, token, coverage.id, job_acu_sched.id, task_acu_sched.id]
      )
    end)

  end

  defp map_request(user_id, member_id, acu_schedule_id, token, coverage_id) do
    params = %{
      user_id: user_id,
      member_id: member_id,
      acu_schedule_id: acu_schedule_id,
      token: token,
      coverage_id: coverage_id
    }
  end

  defp insert_task_acu_schedule(request, job_acu_schedule_id, user_id) do
    job_acu_schedule_id
    |> AcuScheduleContext.task_acu_schedule_params(user_id, request)
    |> AcuScheduleContext.insert_task_acu_schedule()
  end

  defp acu_schedule_members_count(acu_schedule) do
    acu_schedule.acu_schedule_members
    |> Enum.reject(&(&1.status == "removed"))
  end

  def discard_acu_schedule(conn, %{"id" => id}) do
    AcuScheduleContext.delete_acu_schedule(id)
    conn
    |> put_flash(:info, "ACU Schedule successfully deleted.")
    |> redirect(to: "/web/acu_schedules")
  end

  def load_members_tbl(conn, params) do
    count = AcuScheduleDatatable.new_get_clean_asm_count(params["search"]["value"], params["id"])
    acu_schedule_members = AcuScheduleDatatable.new_get_clean_asm(params["start"], params["length"], params["search"]["value"], params["id"])
    conn |> json(%{data: acu_schedule_members, draw: params["draw"], recordsTotal: count, recordsFiltered: count})
  end

  def load_remove_members_tbl(conn, params) do
    count = AcuScheduleDatatable.new_get_clean_removed_asm_count(params["search"]["value"], params["id"])
    acu_schedule_members = AcuScheduleDatatable.new_get_clean_removed_asm(params["start"], params["length"], params["search"]["value"], params["id"])
    conn |> json(%{data: acu_schedule_members, draw: params["draw"], recordsTotal: count, recordsFiltered: count})
  end

  def load_members_tbl_show(conn, params) do
    count = AcuScheduleDatatable.new_get_clean_asm_count(params["search"]["value"], params["id"])
    acu_schedule_members = AcuScheduleDatatable.new_get_clean_asm_show(params["start"], params["length"], params["search"]["value"], params["id"])
    conn |> json(%{data: acu_schedule_members, draw: params["draw"], recordsTotal: count, recordsFiltered: count})
  end

  ##### email #####
  defp send_email_notification(conn, acu_schedule, date_inserted) do
    #{:ok, params}
    acu_schedule
        |> EmailSmtp.send_acu_email(date_inserted)
        |> Mailer.deliver_now()

        conn
        |> put_flash(:info, "We've sent you a mail notification!")
        #|> redirect(to: session_path(conn, :new))
  end

  ##### Export Masterlist #####
  def acu_schedule_export(conn, params) do
    params = params["acu_data"]
    params = Poison.decode!(params)
    id = params["id"]
    datetime = params["datetime"]
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

  def asm_member_load_datatable(conn, %{"params" => params}) do
    asm = AcuScheduleContext.get_all_removed_asm_members_for_modal_v3(params["search"], params["offset"], params["acu_schedule_id"])
    render(conn, Innerpeace.PayorLink.Web.AcuScheduleView, "load_all_acu_schedule_members.json", acu_schedule_members: asm)
  end

  def number_of_members(conn, %{"params" => params}) do
    if params["facility_id"] == "" do
      json(conn, Poison.encode!(0))
    else
      members_count = AcuScheduleContext.new_get_active_members_by_type_count(
        params["facility_id"],
        params["member_type"],
        params["product_code"],
        params["account_code"]
      )
      json(conn, Poison.encode!(members_count))
    end

  end

end
