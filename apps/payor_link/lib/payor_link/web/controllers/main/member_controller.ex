defmodule Innerpeace.PayorLink.Web.Main.MemberController do

    use Innerpeace.PayorLink.Web, :controller
    use Innerpeace.Db.PayorRepo, :context

  alias Innerpeace.Db.Schemas.{
    Member,
    MemberUploadFile,
    MemberUploadLog
  }

  alias Innerpeace.Db.Base.{
    MemberContext,
    UserContext

  }

  alias Innerpeace.Db.Datatables.MemberDatatable
  alias Innerpeace.Db.Base.Api.UtilityContext

  plug :valid_uuid?, %{origin: "members"}
  when not action in [:index]

  alias Innerpeace.Db.Base.Api.UtilityContext

  # plug :can_access?, %{permissions: ["manage_members", "access_members"]} when action in [:index]
  # plug :can_access?, %{permissions: ["manage_members"]} when not action in [:index]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{members: [:manage_members]},
       %{members: [:access_members]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{members: [:manage_members]},
     ]] when not action in [
       :index,
       :show,
       :render_status,
       :load_index,
       :index_2,
       :show_page
     ]

  def index(conn, _params) do
    # members = MemberContext.get_active_without_evoucher()
    # MemberContext.generate_evoucher(members, "payor_link")
    #members = MemberContext.get_all_members_query("", 0)

    render(conn, "index.html")
  end

  def upload_status(conn, nil),
    do: json conn, Poison.encode!(%{valid: false, mul_count: %{total: nil, success: nil, failed: nil}})

  def upload_status(conn, %{"id" => nil}),
    do: json conn, Poison.encode!(%{valid: false, mul_count: %{total: nil, success: nil, failed: nil}})

  def upload_status(conn, %{"id" => id}),
    do: id |> MemberContext.check_upload_status() |> render_status(conn)

  def render_status(result, conn),
    do: json conn, Poison.encode!(result)

  def upload_status(conn, %{}),
    do: json conn, Poison.encode!(%{valid: false, mul_count: %{total: nil, success: nil, failed: nil}})

  def load_index(conn, params) do
    count = MemberDatatable.member_count()

    data =
      params["start"]
      |> MemberDatatable.member_data(
        params["length"],
        params["search"]["value"],
        params["order"]["0"]
      )

    filtered_count =
      params["search"]["value"]
      |> MemberDatatable.member_filtered_count()

    conn
    |> json(%{
      data: data,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  def batch_processing(conn, _), do: render(conn, "batch_processing.html")

  def load_batch_index(conn, params) do
    count = MemberDatatable.batch_count()

    order_column = params["order"]["0"]["column"]
    order_dir = params["order"]["0"]["dir"]

    data = order_and_direction(order_column, order_dir, params)

    filtered_count =
      params["search"]["value"]
      |> MemberDatatable.batch_filtered_count()

    conn
    |> json(%{
      data: data,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  defp order_and_direction("0", "asc", params) do
    data =
      params["start"]
      |> MemberDatatable.batch_data(
        params["length"],
        params["search"]["value"]
      )
  end

  defp order_and_direction("0", "desc", params) do
    data =
      params["start"]
      |> MemberDatatable.batch_data(
        params["length"],
        params["search"]["value"]
      )
  end

  defp order_and_direction("1", "asc", params) do
    data =
      params["start"]
      |> MemberDatatable.batch_data_account_type_asc(
        params["length"],
        params["search"]["value"]
      )
  end

  defp order_and_direction("1", "desc", params) do
    data =
      params["start"]
      |> MemberDatatable.batch_data_account_type_desc(
        params["length"],
        params["search"]["value"]
      )
  end

  defp order_and_direction("7", "asc", params) do
    data =
      params["start"]
      |> MemberDatatable.batch_data_inserted_at_asc(
        params["length"],
        params["search"]["value"]
      )
  end

  defp order_and_direction("7", "desc", params) do
    data =
      params["start"]
      |> MemberDatatable.batch_data_inserted_at_desc(
        params["length"],
        params["search"]["value"]
      )
  end

  defp order_and_direction("8", "asc", params) do
    data =
      params["start"]
      |> MemberDatatable.batch_data_updated_at_asc(
        params["length"],
        params["search"]["value"]
      )
  end

  defp order_and_direction("8", "desc", params) do
    data =
      params["start"]
      |> MemberDatatable.batch_data_updated_at_desc(
        params["length"],
        params["search"]["value"]
      )
  end

  def new(conn, _params) do
    accounts = list_active_accounts()
    changeset = Member.changeset_general(%Member{})
    render(conn, "new.html", accounts: accounts, changeset: changeset)
  end

  def choose_member_upload_type(conn, params) do
    case params["member_type"] do
      "single" ->
        conn
        |> redirect(to: "/web/members/new")
      "batch" ->
        conn
        |> redirect(to: "/web/members/batch_processing")
      _ ->
        conn
        |> put_flash(:error, "Please select upload type.")
        |> render("index.html")
    end
  end

  def create_general(conn, %{"member" => member_params}) do
    member_params = setup_civil_status(member_params)
    accounts = list_active_accounts()
    _changeset = Member.changeset_general(%Member{})
    products = get_all_products()
    if member_params["is_draft"] == "true" do
      member_params = Map.put(member_params, "step", 1)
    else
      member_params = Map.put(member_params, "step", 2)
    end
      member_params = Map.put(member_params, "created_by_id", conn.assigns.current_user.id)
    case create_member(member_params) do
      {:ok, member} ->
        # pass payor id once payor id is implemented
        member
        if member_params["photo"] do
          update_member_photo(member, member_params)
        end
        if member_params["senior_photo"] do
          update_member_senior_photo(member, member_params)
        end
        if member_params["pwd_photo"] do
          update_member_pwd_photo(member, member_params)
        end
        if member_params["skipping_hierarchy"] != [""] do
          MemberContext.update_for_approval_status(member)
          insert_member_hierarchy(member.id, conn.assigns.current_user.id, member_params["skipping_hierarchy"])
        end

        MemberContext.insert_log(%{
          member_id: member.id,
          user_id: conn.assigns.current_user.id,
          message: "Member has been created."
        })

        if member_params["is_draft"] == "true" do
          conn
          |> put_flash(:info, "Member has been saved as draft.")
          |> redirect(to: "/web/members")
        else
          conn
          |> redirect(to: "/web/members/#{member.id}/setup?step=2")
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Employee number is already used within the selected account!")
        |> render("new.html", accounts: accounts,
                  changeset: changeset, products: products)
    end
  end

  def show_page(conn, params) do
    member = get_unutilized_member(params["id"])

    if member == [] do
      conn
      |> put_flash(:error, "Member does not exist.")
      |> redirect(to: "/web/members")
    else
      update_member_status(member.account_code)
      member_status_checker(member)
      authorizations =
        if is_nil(params["member"]["product_id"]) do
          MemberContext.get_authorization_ibnr(member.id)
        else
          get_unutilized_loa_by_product(params["id"], params["member"]["product_id"])
        end

        utilize_authorizations =
          if is_nil(params["member"]["product_id"]) do
            MemberContext.get_claim_actual(member.id)
          else
            get_utilized_loa_by_product(params["id"], params["member"]["product_id"])
          end

          tab =
            if is_nil(params["member"]["product_id"]) do
              "profile"
            else
              "utilization"
            end
            changeset = change_member_movement(%Member{})

            step = member.step

            if step > 3 do
              render(conn, "show.html",
                     member: member,
                     authorizations: authorizations,
                     changeset: changeset,
                     tab: tab,
                     utilize_authorizations: utilize_authorizations)
            else
              conn
              |> put_flash(:error, "Member does not exist.")
              |> redirect(to: "/web/members")
            end
    end
  end

  defp member_status_checker(member) do
    if member.status == "Suspended" do
      MemberContext.reactivation_member(member)
    end
    if member.status == "Active" do
      MemberContext.suspension_member(member)
    end
      MemberContext.expired_member(member)
    if member.status == "Active" or member.status == "Suspended" do
      MemberContext.cancellation_member(member)
    end
    if member.status == "Pending" or member.status == "For Renewal" or is_nil(member.status) do
    end
  end

  defp setup_civil_status(params) do
    with "Dependent" <- params["type"] do
      case params["relationship"] do
        "Spouse" ->
          Map.put(params, "civil_status", "Married")
        "Child" ->
          Map.put(params, "civil_status", "Single")
        "Sibling" ->
          Map.put(params, "civil_status", "Single")
        _ ->
          params
      end
    else
      _ ->
        params
    end
  end

  def setup(conn, %{"id" => id, "step" => step}) do
    member = MemberContext.get_member!(id)
    if is_nil(member) do
      conn
      |> put_flash(:error, "Member does not exist.")
      |> redirect(to: main_member_path(conn, :index))
    else
      steps(conn, member, step)
    end
  end

  defp steps(conn, member, "1"), do: step1(conn, member)
  defp steps(conn, member, "2"), do: step2(conn, member)
  defp steps(conn, member, "3"), do: step3(conn, member)
  defp steps(conn, member, _) do
    conn
    |> put_flash(:error, "Invalid step!")
    |> redirect(to: main_member_path(conn, :index))
  end

  def setup(conn, %{"id" => id}) do
    conn
    |> put_flash(:error, "Invalid step!")
    |> redirect(to: main_member_path(conn, :index))
  end

  def step3(conn, member) do
    render(conn, "step3.html", member: member)
  end

  def update_setup(conn, %{"id" => id, "step" => step, "member" => member_params}) do
    member = get_member!(id)
    if is_nil(member) do
      conn
      |> put_flash(:error, "Member does not exist.")
      |> redirect(to: main_member_path(conn, :index))
    else
      update_steps(conn, member, step, member_params)
    end
  end

  defp update_steps(conn, member, "1", member_params), do: step1_update(conn, member, member_params)
  defp update_steps(conn, member, "2", member_params), do: step2_update(conn, member, member_params)
  defp update_steps(conn, member, "3", member_params), do: step3_update(conn, member, member_params)
  defp update_steps(conn, member, "3.1", member_params), do: step3_update_product(conn, member, member_params)
  defp update_steps(conn, member, _, member_params) do
    conn
    |> put_flash(:error, "Invalid step!")
    |> redirect(to: main_member_path(conn, :index))
  end

  def step1(conn, member) do
    accounts = list_active_accounts()
    changeset = Member.changeset_general(member)
    render(conn, "step1_edit.html", accounts: accounts, changeset: changeset, member: member)
  end

  def step1_update(conn, member, member_params) do
    old_member_type = member.type
    member_params = setup_civil_status(member_params)
    member_params = member_params_put_principal(member_params, member_params["type"])
    member_params = member_params_put_senior(member_params, member_params["senior"])
    member_params = member_params_put_pwd(member_params, member_params["pwd"])
    member_params = Map.put(member_params, "updated_by_id", conn.assigns.current_user.id)
    accounts = list_active_accounts()
    case update_member_general(member, member_params) do
      {:ok, member} ->
        if old_member_type != member.type do
          clear_member_products(member.id)
        end
        if member_params["photo"] do
          update_member_photo(member, member_params)
        end
        if member_params["senior_photo"] do
          update_member_senior_photo(member, member_params)
        end
        if member_params["pwd_photo"] do
          update_member_pwd_photo(member, member_params)
        end
      if member_params["skipping_hierarchy"] != [""] do
        MemberContext.update_for_approval_status(member)
        insert_member_hierarchy(member.id, conn.assigns.current_user.id, member_params["skipping_hierarchy"])
      else
        MemberContext.delete_skipping_for_edit(member.id)
        MemberContext.update_status_to_nil(member)
      end

      MemberContext.insert_log(%{
        member_id: member.id,
        user_id: conn.assigns.current_user.id,
        message: "Member's general step has been updated."
      })
      conn
      |> redirect(to: "/web/members/#{member.id}/setup?step=2")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Employee number is already used within the selected account!")
        |> render("step1_edit.html", accounts: accounts, changeset: changeset, member: member)
    end
  end

  defp member_params_put_principal(member_params, "Principal"), do: Map.put(member_params, "principal_id", "")
  defp member_params_put_principal(member_params, _), do: member_params

  defp member_params_put_senior(member_params, "false"), do: Map.put(member_params, "senior_id", "")
  defp member_params_put_senior(member_params, _), do: member_params

  defp member_params_put_pwd(member_params, "false"), do: Map.put(member_params, "pwd_id", "")
  defp member_params_put_pwd(member_params, _), do: member_params

  def step2(conn, member) do
    changeset = Member.changeset_contact(member)
    render(conn, "step2.html", member: member, changeset: changeset)
  end

  def step2_update(conn, member, member_params) do
    member_params = step2_save_as_draft(member_params, member_params["save_as_draft"])
    member_params = Map.put(member_params, "updated_by_id", conn.assigns.current_user.id)
    case update_member_contact(member, member_params) do
      {:ok, member} ->
        MemberContext.insert_log(%{
          member_id: member.id,
          user_id: conn.assigns.current_user.id,
          message: "Member's contact step has been filled."
        })

        step2_redirect(conn, member,  member_params["save_as_draft"])
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> render("step2.html", member: member, changeset: changeset)
    end
  end

  defp step2_save_as_draft(member_params, "yes"), do: Map.put(member_params, "step", 2)
  defp step2_save_as_draft(member_params, _), do: Map.put(member_params, "step", 3)

  defp step2_redirect(conn, member, "yes") do
    conn
    |> put_flash(:info, "Member successfully save as draft.")
    |> redirect(to: "/web/members")
  end

  defp step2_redirect(conn, member, _) do
    conn
    |> redirect(to: "/web/members/#{member.id}/setup?step=3")
  end

  def add_member_product(conn, %{"id" => id, "member" => member_params}) do
    member = get_member!(id)
    account_product_ids = String.split(member_params["account_product_ids_main"], ",")
    if account_product_ids == [""] do
      conn
      |> put_flash(:error, "Please select at least one plan!")
      |> redirect(to: "/web/members/#{member.id}")
    else
      case set_member_products(member, account_product_ids) do
        {:ok} ->
          MemberContext.add_member_product_log(conn.assigns.current_user, account_product_ids, member.id)
          conn
          |> redirect(to: "/web/members/#{member.id}?tab=product")
        {:error} ->
          conn
          |> put_flash(:error, "You are only allowed to enter one plan with ACU Benefit.")
          |> redirect(to: "/web/members/#{member.id}?tab=product")
        {:acu_mp_already_exist} ->
          conn
          |> put_flash(:error, "You are only allowed to enter one plan with ACU Benefit")
          |> redirect(to: "/web/members/#{member.id}?tab=product")
      end
    end
  end

  def delete_member_all(conn, %{"id" => id}) do
    MemberContext.delete_member_all(id)

    json conn, Poison.encode!(%{valid: true})

    rescue
    _ ->
    json conn, Poison.encode!(%{valid: false})

  end

  def delete_member_product(conn, %{"member_id" => member_id, "id" => member_product_id}) do
    with {true, id} <- UtilityContext.valid_uuid?(member_id),
         member = %Member{} <- get_member!(member_id),
         {:ok, member_product} <- validate_member_product(conn, member, member_product_id),
         {:valid} <- validate_amp(conn, MemberContext.get_authorization_member_products(member_product_id))
    do
      account_product_id = member_product.account_product.id
      MemberContext.delete_member_account_product(member.id, member_product_id)
      MemberContext.delete_member_product_log(conn.assigns.current_user, account_product_id, member_id)
      json conn, Poison.encode!(%{valid: true})
    else

      {:error} ->
        json conn, Poison.encode!(%{valid: false, coverage: "ACU"})
      _ ->
        json conn, Poison.encode!(%{valid: false, coverage: "other"})
    end
  end
  def delete_member_product(conn, _), do: json conn, Poison.encode!(%{valid: false, coverage: "other"})

  defp validate_member_product(conn, member, nil) do
    conn
    |> put_flash(:error, "Member Plan not found")
    |> redirect(to: "/members/#{member.id}")
  end
  defp validate_member_product(conn, member, mp_id), do:
    get_member_product1(conn, MemberContext.get_member_product(mp_id))

  defp get_member_product1(conn, []), do: json_poison(conn, false, "other")
  defp get_member_product1(conn, member_products) do
    member_products
    |> List.first()
    |> get_member_product2(conn)
  end

  defp get_member_product2(nil, conn), do: json_poison(conn, false, "other")
  defp get_member_product2(member_product, _), do: {:ok, member_product}

  defp validate_amp(_, []), do: {:valid}
  defp validate_amp(conn, _), do: json_poison(conn, false, "other")

  defp json_poison(conn, valid, coverage), do: json(conn, Poison.encode!(%{valid: valid, coverage: coverage}))

  def step3_update_product(conn, member, member_params) do
    link = step3_link(member_params["is_edit"])
    with {:ok, ids} <- get_account_product_ids(member_params["account_product_ids_main"]),
         {:ok} <- set_member_products(member, ids)
    do
      is_step3?(member_params["is_edit"], member, conn.assigns.current_user.id)
      conn
      |> put_flash(:info, "Successfully added plan")
      |> redirect(to: "/web/members/#{member.id}/#{link}")
    else
      {:error} ->
        prompt_error(conn, member, link, "Error adding plan!")
      _ ->
        prompt_error(conn, member, link, "Please select at least one plan!")
    end
  rescue
    _ ->
      prompt_error(conn, member, "", "Error adding plan!")
  end

  defp step3_link("true"), do: "edit?tab=product"
  defp step3_link(_), do: "setup?step=3"

  defp is_step3?("true", _, _), do: ""
  defp is_step3?(_, member, user_id), do:
    update_member_step(member, %{"step" => 3, "updated_by_id" => user_id})

  defp get_account_product_ids(nil), do: []
  defp get_account_product_ids(""), do: []
  defp get_account_product_ids([]), do: []
  defp get_account_product_ids([""]), do: []
  defp get_account_product_ids(ids), do: {:ok, String.split(ids, ",")}

  defp prompt_error(conn, member, link, message) do
    conn
    |> put_flash(:error, message)
    |> redirect(to: "/web/members/#{member.id}/#{link}")
  end

  def step3_update(conn, member, member_params) do
    member_product_tier = member_params["product_tier"]
    if member_product_tier == "" do
      conn
      |> redirect(to: "/web/members/#{member.id}/setup?step=3")

    else

      enrollment_date =
      Ecto.Date.utc()

      card_expiry_date =
      enrollment_date
      |> Timex.shift(years: 4)

      enroll_member(member, %{
        "step" => 4,
        "updated_by_id" => conn.assigns.current_user.id,
        "enrollment_date" => enrollment_date,
        "card_expiry_date" => card_expiry_date
      })
      MemberContext.create_member_log(
        conn.assigns.current_user,
        member
      )

      # Compute time from today to effectivity date in seconds
      {_, {year, month, day}} =
        member.effectivity_date
        |> Ecto.Date.dump()

      schedule = %DateTime{
        year: year,
        month: month,
        day: day,
        zone_abbr: "SGT",
        hour: 0,
        minute: 0,
        second: 0,
        microsecond: {0, 0},
        utc_offset: 28800,
        std_offset: 0,
        time_zone: "Singapore"
      }

      Exq.Enqueuer.start_link

      # Insert in job queue
      Exq.Enqueuer
      |> Exq.Enqueuer.enqueue_at(
        "member_activation_job",
        schedule,
        "Innerpeace.Db.Worker.Job.ActivateMemberJob",
        [member.id]
      )

      MemberContext.insert_log(%{
        member_id: member.id,
        user_id: conn.assigns.current_user.id,
        message: "Member's product step has been filled."
      })

      member
      |> Member.changeset_card()
      |> Innerpeace.Db.Repo.update()
      update_product_tier(member_product_tier |> String.split(","))
      conn
      |> put_flash(:info, "Member was successfully Created")
      |> redirect(to: "/web/members")

    end
  end

  ########Edit
  # def edit_setup(conn, %{"id" => id, "tab" => tab}) do
  #   with {:true, id} <- UtilityContext.valid_uuid?(id),
  #        member = %Member{} <- MemberContext.get_member!(id) do
  #     case tab do
  #       "general" ->
  #         edit_general(conn, member)
  #       # "products" ->
  #       #   edit_products(conn, member)
  #       # "contact" ->
  #       #   edit_contact(conn, member)
  #       _ ->
  #         conn
  #         |> put_flash(:error, "Invalid tab")
  #         |> redirect(to: member_path(conn, :show, member))
  #     end
  #   else
  #     _ ->
  #       conn
  #       |> put_flash(:error, "Page not found")
  #       |> redirect(to: member_path(conn, :index))
  #   end
  # end

  # def edit_setup(conn, %_
  #   conn
  #   |> put_flash(:error, "Page not found")
  #   |> redirect(to: member_path(conn, :index))
  # end

  # def edit_setup(conn, member) do
  #   changeset = Member.changeset_general(member)
  #   render(conn, "edit/general.html", changeset: changeset, member: member)
  # end

  def edit_setup(conn, %{"id" => id, "tab" => tab}) when tab == "general" do
    member = MemberContext.get_member!(id)
    accounts = list_active_accounts()
    changeset = Member.changeset_general(member)
    render(conn, "edit/general.html", changeset: changeset, member: member, accounts: accounts)
  end

  def update_general(conn, %{"id" => id, "member" => member_params}) do
    member = MemberContext.get_member!(id)
    old_member_type = member.type
    member_params = setup_civil_status(member_params)
    if member_params["type"] == "Principal" do
      Map.put(member_params, "principal_id", "")
    end

    # if member_params["senior"] == "false" do
    #   member_params = Map.put(member_params, "senior_id", "")
    # else
    #   member_params
    # end

    ## PWD ID in old design are still exist when pwd are equal to false
    if member_params["pwd"] == "false" do
      member_params = Map.put(member_params, "pwd_id", "")
    else
      member_params
    end
    member_params =
      member_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
      |> Map.put("status", "Active")
    accounts = list_active_accounts()
    case update_member_general(member, member_params) do
      {:ok, member} ->
        MemberContext.insert_log(%{
          member_id: member.id,
          user_id: conn.assigns.current_user.id,
          message: "Member's general step has been edited."
        })
        if old_member_type != member.type do
          clear_member_products(member.id)
        end
        if member_params["photo"] do
          update_member_photo(member, member_params)
        end
        if member_params["senior_photo"] do
          update_member_senior_photo(member, member_params)
        end
        if member_params["pwd_photo"] do
          update_member_pwd_photo(member, member_params)
        end
        if member_params["skipping_hierarchy"] != [""] do
          MemberContext.update_for_approval_status(member)
          insert_member_hierarchy(member.id, conn.assigns.current_user.id, member_params["skipping_hierarchy"])
        else
          MemberContext.delete_skipping_for_edit(member.id)
          # MemberContext.update_status_to_nil(member)
        end
        conn
        |> put_flash(:info, "Member was successfully updated!")
        |> redirect(to: "/web/members/#{member.id}/edit?tab=general")

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please check your params!")
        |> render("edit/general.html", changeset: changeset, member: member, accounts: accounts)
    end
  end

  def edit_setup(conn, %{"id" => id, "tab" => tab}) when tab == "contact" do
    member = MemberContext.get_member!(id)
    changeset = Member.changeset_contact(member)
    render(conn, "edit/contact.html", member: member, changeset: changeset)
  end

  def update_contact(conn, %{"id" => id, "member" => member_params}) do
    member = MemberContext.get_member!(id)
    member_params =
      member_params
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
      |> Map.put("status", "Active")
    case update_member_contact(member, member_params) do
      {:ok, member} ->
        MemberContext.insert_log(%{
          member_id: member.id,
          user_id: conn.assigns.current_user.id,
          message: "Member's contact step has been edited."
        })
        conn
        |> put_flash(:info, "Member was successfully updated!")
        |> redirect(to: "/web/members/#{member.id}/edit?tab=contact")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please check your params!")
        |> render("edit/contact.html", member: member, changeset: changeset)
    end
  end

  def edit_setup(conn, %{"id" => id, "tab" => tab}) when tab == "product" do
    member = MemberContext.get_member!(id)
    render(conn, "edit/product.html", member: member)
  end

  def update_product(conn, %{"id" => id, "member" => member_params}) do
    member = MemberContext.get_member!(id)

    account_product_ids = String.split(member_params["account_product_ids_main"], ",")
    if account_product_ids == [] do
      conn
      |> put_flash(:error, "Please select at least one plan!")
      |> render("edit/product.html", member: member)
    else
      case set_member_products(member, account_product_ids) do
        {:ok} ->
          MemberContext.insert_log(%{
            member_id: member.id,
            user_id: conn.assigns.current_user.id,
            message: "Member's product step has been edited."
          })
          conn
          |> put_flash(:info, "Member was successfully updated!")
          |> redirect(to: "/web/members/#{member.id}/edit?tab=product")
        {:error} ->
          conn
          |> put_flash(:error, "You are only allowed to enter one plan with ACU Benefit.")
          |> render("edit/product.html", member: member)
        {:acu_mp_already_exist} ->
          conn
          |> put_flash(:error, "You are only allowed to enter one plan with ACU Benefit")
          |> render("edit/product.html", member: member)
      end
    end
  end

# https://sentry.medilink.com.ph/medilink/payorlink/issues/456/
  def edit_setup(conn, params), do: redirect_to_index(conn, "Page not found!")

  defp redirect_to_index(conn, message) do
    conn
    |> put_flash(:error, message)
    |> redirect(to: member_path(conn, :index))
  end

  def import_member(conn, %{"member" => member_params}) do
    if Enum.count(member_params) == 1, do:
      conn
      |> put_flash(:error, "Please choose a file.")
      |> redirect(to: "/web/members/batch_processing")

    member_params = Map.put_new(member_params, "upload_type", "Enrollment")
    # case create_member_import(member_params, conn.assigns.current_user.id) do
    case create_member_import_worker(member_params, conn.assigns.current_user.id) do
      {:ok} ->
        conn
        |> put_flash(:info, "Batch successfully uploaded.")
        |> redirect(to: "/web/members/batch_processing")
      {:not_found} ->
        conn
        |> put_flash(:error, "File has empty records.")
        |> redirect(to: "/web/members/batch_processing")
      {:not_equal} ->
        conn
        |> put_flash(:error, "Invalid column format")
        |> redirect(to: "/web/members/batch_processing")
      {:not_equal, columns} ->
        conn
        |> put_flash(:error, "File has missing column/s: #{columns}")
        |> redirect(to: "/web/members/batch_processing")
      {:invalid_format} ->
        conn
        |> put_flash(:error, "Acceptable files is .csv")
        |> redirect(to: "/web/members/batch_processing")
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Oops, something went wrong.")
        |> redirect(to: "/web/members/batch_processing")
    end

  end

  def get_pwd_id(conn, _params) do
    members = MemberContext.get_pwd_id()
    json conn, Poison.encode!(members)
  end

  def get_senior_id(conn, _params) do
    members = MemberContext.get_senior_id()
    json conn, Poison.encode!(members)
  end

end
