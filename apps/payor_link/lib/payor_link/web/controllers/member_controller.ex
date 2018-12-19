defmodule Innerpeace.PayorLink.Web.MemberController do
  use Innerpeace.PayorLink.Web, :controller
  use Innerpeace.Db.PayorRepo, :context

  alias Innerpeace.Db.Datatables.MemberDatatable
  alias Innerpeace.Db.Schemas.{
    Member
  }

  alias Innerpeace.Db.Base.{
    MemberContext,
    UserContext
  }

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
       :show
     ]

  plug :valid_uuid?, %{origin: "members"}
  when not action in [:index]

  alias Innerpeace.Db.Base.Api.UtilityContext

  def index(conn, _params) do
    pem = conn.private.guardian_default_claims["pem"]["members"]
    # local_path = Application.get_env(:payor_link, Innerpeace.PayorLink.FileTransferProtocol) |> Keyword.get(:claims_dir)
    # MemberContext.ftp_transfer_file("test1.txt", local_path)
    # MemberContext.generate_claims_file()
    # members = MemberContext.get_active_without_evoucher()
    # MemberContext.generate_evoucher(members, "payor_link")
    members = MemberContext.get_all_members_query("", 0)
    # members = paginate_members.entries
    render(conn, "index.html", members: members, permission: pem)
  end

  def reports_index(conn, _params) do
    accounts = list_active_accounts()
    render(conn, "generate_reports.html", results: [], accounts: accounts)
  end

  def generate_reports(conn, %{"params" => params}) do
    accounts = list_active_accounts()
    case MemberContext.account_group_member_search(params) do
      {:ok, results} ->
        render(conn, "generate_reports.html", results: results, accounts: accounts)
      _ ->
        conn
        |> put_flash(:error, "Invalid Search")
        |> redirect(to: member_path(conn, :generate_reports))
    end
  end

  def csv_get_account_members(conn, %{"account_group_code" => account_group_code, "am_param" => am_param}) do
    data = [["Type", "Account_Name", "First_Name", "Middle_Name", "Last_Name", "Member_Type", "Card_No.", "Status"]] ++
      MemberContext.account_member_csv_download(am_param, account_group_code)
      |> CSV.encode
      |> Enum.to_list
      |> to_string

    conn
    |> json(data)
  end

  def index_load_datatable(conn, %{"params" => params}) do
    members = MemberContext.get_all_members_query(params["search"], params["offset"])
    render(conn, Innerpeace.PayorLink.Web.MemberView, "load_search_members.json", members: members)

    rescue
    _ ->
      json conn, Poison.encode!(%{valid: false})
  end

  def new(conn, _params) do
    accounts = list_active_accounts()
    changeset = Member.changeset_general(%Member{})
    render(conn, "step1.html", accounts: accounts, changeset: changeset)
  end


  def show(conn, params) do
    pem = conn.private.guardian_default_claims["pem"]["members"]
    id = params["id"]
    member = get_unutilized_member(id)
    if member == [] do
      conn
      |> put_flash(:error, "Member does not exist.")
      |> redirect(to: member_path(conn, :index))
    else
      update_member_status(member.account_code)
      member_status_checker(member)
      authorizations =
        if is_nil(params["member"]["product_id"]) do
          MemberContext.get_authorization_ibnr(member.id)
        else
         get_unutilized_loa_by_product(id, params["member"]["product_id"])
        end

        utilize_authorizations =
          if is_nil(params["member"]["product_id"]) do
            MemberContext.get_claim_actual(member.id)
          else
           get_utilized_loa_by_product(id, params["member"]["product_id"])
          end

        tab =
          if is_nil(params["member"]["product_id"]) do
            "profile"
          else
            "utilization"
          end
          changeset = change_member_movement(%Member{})
          render(conn, "show.html", member: member, authorizations: authorizations, changeset: changeset, tab: tab, utilize_authorizations: utilize_authorizations, permission: pem)
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

  def create_general(conn, %{"member" => member_params}) do
    member_params =
      member_params
      |> translate_date_params()
      |> setup_civil_status()
    accounts = list_active_accounts()
    member_params = Map.put(member_params, "step", 2)
    member_params = Map.put(member_params, "created_by_id", conn.assigns.current_user.id)
    case create_member(member_params) do
      {:ok, member} ->
        # pass payor id once payor id is implemented
        member
        |> update_member_card

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
        conn
        |> redirect(to: "/members/#{member.id}/setup?step=2")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Employee number is already used within the selected account!")
        |> render("step1.html", accounts: accounts, changeset: changeset)
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
    member = get_member!(id)
    case step do
      "1" ->
        step1(conn, member)
      "2" ->
        step2(conn, member)
      "3" ->
        step3(conn, member)
      "4" ->
        step4(conn, member)
      _ ->
        conn
        |> put_flash(:error, "Invalid step!")
        |> redirect(to: member_path(conn, :index))
    end
  end

  def setup(conn, %{"id" => id}) do
    conn
    |> put_flash(:error, "Invalid step!")
    |> redirect(to: member_path(conn, :index))
  end

  def update_setup(conn, %{"id" => id, "step" => step, "member" => member_params}) do
    member = get_member!(id)
    case step do
      "1" ->
        step1_update(conn, member, member_params)
      "2" ->
        step2_update(conn, member, member_params)
      "2.1" ->
        step2_update_tier(conn, member, member_params)
      "3" ->
        step3_update(conn, member, member_params)
      "4" ->
        step4_update(conn, member, member_params)
      _ ->
        conn
        |> put_flash(:error, "Invalid step!")
        |> redirect(to: member_path(conn, :index))
    end
  end

  def step1(conn, member) do
    accounts = list_active_accounts()
    principal_members = get_principal_members()
    changeset = Member.changeset_general(member)
    render(conn, "step1_edit.html", accounts: accounts, changeset: changeset, principal_members: principal_members, member: member)
  end

  def step1_update(conn, member, member_params) do
    old_member_type = member.type
    member_params =
      member_params
      |> translate_date_params()
      |> setup_civil_status()
    if member_params["type"] == "Principal" do
      Map.put(member_params, "principal_id", "")
    end

    if member_params["senior"] == "false" do
      member_params = Map.put(member_params, "senior_id", "")
    else
      member_params
    end

    member_params = Map.put(member_params, "updated_by_id", conn.assigns.current_user.id)
    accounts = list_active_accounts()
    principal_members = get_principal_members()
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
        conn
        |> redirect(to: "/members/#{member.id}/setup?step=2")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Employee number is already used within the selected account!")
        |> render("step1_edit.html", accounts: accounts, changeset: changeset, principal_members: principal_members, member: member)
    end
  end

  def step2(conn, member) do
    render(conn, "step2.html", member: member)
  end

  def step2_update(conn, member, member_params) do
    account_product_ids = String.split(member_params["account_product_ids_main"], ",")
    if account_product_ids == [""] do
      conn
      |> put_flash(:error, "Please select at least one plan!")
      |> render("step2.html", member: member)
    else
      case set_member_products(member, account_product_ids) do
        {:ok} ->
          update_member_step(member, %{"step" => 3, "updated_by_id" => conn.assigns.current_user.id})
          conn
          |> put_flash(:info, "Successfully added plan")
          |> redirect(to: "/members/#{member.id}/setup?step=2")
        # {:error} ->
        #   conn
        #   |> put_flash(:error, "You are only allowed to enter 1 plan with ACU Benefit.")
        #   |> render("step2.html", member: member)
        # {:acu_mp_already_exist} ->
        #   conn
        #   |> put_flash(:error, "You are only allowed to enter 1 plan with ACU Benefit")
        #   |> render("step2.html", member: member)
      end
    end
  end

  def step2_update_tier(conn, member, member_params) do
    member_product_tier = member_params["product_tier"]
    if member_product_tier == "" do
      conn
      |> redirect(to: "/members/#{member.id}/setup?step=3")
    else
      update_product_tier(member_product_tier |> String.split(","))
      conn
      |> redirect(to: "/members/#{member.id}/setup?step=3")
    end
  end

  def step3(conn, member) do
    changeset = Member.changeset_contact(member)
    render(conn, "step3.html", member: member, changeset: changeset)
  end

  def step3_update(conn, member, member_params) do
    member_params = Map.put(member_params, "step", 4)
    member_params = Map.put(member_params, "updated_by_id", conn.assigns.current_user.id)
    case update_member_contact(member, member_params) do
      {:ok, member} ->
        conn
        |> redirect(to: "/members/#{member.id}/setup?step=4")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> render("step3.html", member: member, changeset: changeset)
    end
  end

  def step4(conn, member) do
    render(conn, "step4.html", member: member)
  end

  def step4_update(conn, member, member_params) do
    enrollment_date =
      Ecto.Date.utc()

    card_expiry_date =
      enrollment_date
      |> Timex.shift(years: 4)

    enroll_member(member, %{
      "step" => 5,
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

    conn
    |> put_flash(:info, "Successfully enrolled Member")
    |> redirect(to: member_path(conn, :show, member))
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

  # for adding products on show page
  def add_member_product(conn, %{"id" => id, "member" => member_params}) do
    member = get_member!(id)
    account_product_ids = String.split(member_params["account_product_ids_main"], ",")
    if account_product_ids == [""] do
      conn
      |> put_flash(:error, "Please select at least one plan!")
      |> redirect(to: "/members/#{member.id}")
    else
      case set_member_products(member, account_product_ids) do
        {:ok} ->
          MemberContext.add_member_product_log(conn.assigns.current_user, account_product_ids, member.id)
          conn
          |> redirect(to: "/members/#{member.id}?tab=product")
        {:error} ->
          conn
          |> put_flash(:error, "You are only allowed to enter one plan with ACU Benefit.")
          |> redirect(to: "/members/#{member.id}?tab=product")
        {:acu_mp_already_exist} ->
          conn
          |> put_flash(:error, "You are only allowed to enter one plan with ACU Benefit")
          |> redirect(to: "/members/#{member.id}?tab=product")
      end
    end
  end

  # for saving product tier on show page
  def save_member_prduct_tier(conn, %{"id" => id, "member" => member_params}) do
    member = get_member!(id)
    member_product_tier = member_params["product_tier"]
    if member_product_tier == "" do
      conn
      |> redirect(to: "/members/#{member.id}?tab=product")
    else
      MemberContext.show_update_product_tier(member_product_tier |> String.split(","), member, conn.assigns.current_user)
      conn
      |> put_flash(:info, "Successfully updated plan tier")
      |> redirect(to: "/members/#{member.id}?tab=product")
    end
  end

  def get_members_by_account_group(conn, %{"id" => member_id, "account_group_code" => account_group_code}) do
    members =
      if member_id == "" do
        list_members_by_account_group(account_group_code)
      else
        list_members_by_account_group(member_id, account_group_code)
      end
    json conn, Poison.encode!(members)
  end

  def get_members_by_account_group(conn, %{"account_group_code" => account_group_code}) do
    members =list_members_by_account_group(account_group_code)
    json conn, Poison.encode!(members)
  end

  def get_members_by_account_group(conn, params), do: json conn, Poison.encode!([])

  def get_member_details(_conn, %{"id" => member_id}) do
    member = get_member_product_tier1(member_id)
  end

  # Batch Upload
  def new_import(conn, _params) do
    member_upload_files = get_member_upload_logs_payorlink()
    render(conn, "import.html", member_upload_files: member_upload_files)
  end

  def import_member(conn, %{"member" => member_params}) do
    if Enum.count(member_params) == 1, do:
      conn
      |> put_flash(:error, "Please choose a file.")
      |> redirect(to: "/members/enrollment/import")

    member_params = Map.put_new(member_params, "upload_type", "Enrollment")
    # case create_member_import(member_params, conn.assigns.current_user.id) do
    case create_member_import_worker(member_params, conn.assigns.current_user.id) do
      {:ok} ->
        conn
        |> put_flash(:info, "Batch successfully uploaded.")
        |> redirect(to: "/members/enrollment/import")
      {:not_found} ->
        conn
        |> put_flash(:error, "File has empty records.")
        |> redirect(to: "/members/enrollment/import")
      {:not_equal} ->
        conn
        |> put_flash(:error, "Invalid column format")
        |> redirect(to: "/members/enrollment/import")
      {:not_equal, columns} ->
        conn
        |> put_flash(:error, "File has missing column/s: #{columns}")
        |> redirect(to: "/members/enrollment/import")
      {:invalid_format} ->
        conn
        |> put_flash(:error, "Acceptable files is .csv")
        |> redirect(to: "/members/enrollment/import")
      {:not_readable} ->
        conn
        |> put_flash(:error, "CSV file is not readable")
        |> redirect(to: "/members/enrollment/import")
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Oops, something went wrong.")
        |> redirect(to: "/members/enrollment/import")
    end

  end

  def import_member(conn, _params) do
    conn
    |> put_flash(:error, "Please choose a file.")
    |> redirect(to: "/members/enrollment/import")
  end

  def download_corporate_template(conn, _params) do
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"Member (Corporate).csv\"")
    |> send_resp(200, corporate_template_content())
  end

  def download_ifg_template(conn, _params) do
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"Member (IFG).csv\"")
    |> send_resp(200, ifg_template_content())
  end

  def download_cop(conn, _params) do
    # Change of Product

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"Member (Change of Plan).csv\"")
    |> send_resp(200, cop_template_content())
  end

  defp cop_template_content do
    # Change of Product

    _csv_content = [[
      'Member ID',
      'Change of Plan Effective Date',
      'Old Plan Code',
      'New Plan Code',
      'Reason'
    ], [
      '(Required) Member ID of the member',
      '(Required) Date must be in mmm dd, yyyy format',
      '(Required) This plan will be the plan to be changed or removed',
      '(Required) This plan will replace the plan to be removed',
      '(Required) Must be containing 255 alphanumeric and special characters only.'
    ], ['', '', '', '', '', '', '']]
    |> CSV.encode
    |> Enum.to_list
    |> to_string
  end

  defp corporate_template_content do
    _csv_content = [[
      'Account Code', 'Employee No', 'Member Type', 'Relationship', 'Effective Date',
      'Expiry Date', 'First Name', 'Middle Name / Initial', 'Last Name', 'Suffix',
      'Gender', 'Civil Status', 'Birthdate', 'Mobile No', 'Email',
      'Date Hired', 'Regularization Date', 'Address', 'City', 'Plan Code',
      'For Card Issuance', 'Tin No', 'Philhealth', 'Philhealth No', 'Remarks'
    ], [
      '(Required) Account Code of the Account',
      '(Required) Employee No. of the Principal or Guardian',
      '(Required) Member type of member: Principal Dependent Guardian',
      '(Required for dependents) Spouse Child Parent Sibling',
      '(Required) Date must be in mmm dd, yyyy format',
      '(Optional) Date must be in mmm dd, yyyy format',
      '(Required) Must be containing 150 characters consist of letters and dot (.) comma (,) and hyphen (-)',
      '(Optional) Must be containing 150 characters consist of letters and dot (.) comma (,) and hyphen (-)',
      '(Required) Must be containing 150 characters consist of letters and dot (.) comma (,) and hyphen (-)',
      '(Optional) Must be containing 10 characters consist of letters and dot (.) comma (,) and hyphen (-)',
      '(Required) Male or Female',
      '(Required) Status: Single Single Parent Married Widow / Widower Annulled Separated',
      '(Required) Date must be in mmm dd, yyyy format',
      '(Optional) Must be 11 digits only. Format must be 09********',
      '(Optional) Must contain alphanumeric characters with special characters dot (.)  hypen (-), at (@) and underscore(_)',
      '(Optional) Date must be in mmm dd, yyyy format',
      '(Optional) Date must be in mmm dd, yyyy format',
      '(Optional) Address of the member',
      '(Optional) City Address of the member',
      '(Required) Plan code of the plan of the member',
      '(Required) Yes No',
      '(Optional) Must be containing twelve(12) numeric characters only',
      '(Required) Required to file Optional to file Not Covered',
      '(Optional) Must be containing twelve(12) numeric characters only',
      '(Optional) Must be containing 250 alphanumeric and special characters only.'
    ], ['', '', '', '', '', '', '']]
    |> CSV.encode
    |> Enum.to_list
    |> to_string
  end

  defp ifg_template_content do
    _csv_content =
      [
        [
          'Account Code',
          'Principal Number',
          'Member Type',
          'Relationship',
          'Effective Date',
          'Expiry Date',
          'First Name',
          'Middle Name / Initial',
          'Last Name',
          'Suffix',
          'Gender',
          'Civil Status',
          'Birthdate',
          'Mobile No',
          'Email',
          'Address',
          'City',
          'Plan Code',
          'For Card Issuance',
          'Tin No',
          'Philhealth',
          'Philhealth No',
          'Remarks'
        ],
        [
          '(Required) Account Code of the Account',
          '(Required) Employee No. of the Principal or Guardian',
          '(Required) Member type of member: Principal Dependent Guardian',
          '(Required for dependents) Spouse Child Parent Sibling',
          '(Required) Date must be in mmm dd, yyyy format',
          '(Optional) Date must be in mmm dd, yyyy format',
          '(Required) Must be containing 150 characters consist of letters and dot (.) comma (,) and hyphen (-)',
          '(Optional) Must be containing 150 characters consist of letters and dot (.) comma (,) and hyphen (-)',
          '(Required) Must be containing 150 characters consist of letters and dot (.) comma (,) and hyphen (-)',
          '(Optional) Must be containing 10 characters consist of letters and dot (.) comma (,) and hyphen (-)',
          '(Required) Male or Female',
          '(Required) Status: Single Single Parent Married Widow / Widower Annulled Separated',
          '(Required) Date must be in mmm dd, yyyy format',
          '(Optional) Must be 11 digits only. Format must be 09********',
          '(Optional) Must contain alphanumeric characters with special characters dot (.)  hypen (-), at (@) and underscore(_)',
          '(Optional) Address of the member',
          '(Optional) City Address of the member',
          '(Required) Plan code of the plan of the member',
          '(Required) Yes No',
          '(Optional) Must be containing twelve(12) numeric characters only',
          '(Required) Required to file Optional to file Not Covered',
          '(Optional) Must be containing twelve(12) numeric characters only',
          '(Optional) Must be containing 250 alphanumeric and special characters only.'
        ],
        ['', '', '', '', '', '', '']
      ]
    |> CSV.encode
    |> Enum.to_list
    |> to_string
  end

  def member_batch_download(conn, %{"log_id" => log_id, "status" => status, "type" => type}) do
    type = String.downcase(type)
    if type == "change of plan" do
      data =
        [[
          'Upload Status',
          'Member ID',
          'Change of Plan Effective Date',
          'Old Plan Code',
          'New Plan Code',
          'Reason'
        ]]

      data =
        data ++ get_cop_member_batch_log(log_id, status, type)
        |> CSV.encode
        |> Enum.to_list
        |> to_string

      conn
      |> json(data)
    else
      data =
        if type == "corporate" || type == "enrollment" do
          if status == "success" do
            [[
              'Upload Status', 'Card No', 'Account Code', 'Employee No',
              'Member Type', 'Relationship', 'Effective Date',
              'Expiry Date', 'First Name', 'Middle Name', 'Last Name', 'Suffix',
              'Gender', 'Civil Status', 'Birthdate', 'Mobile No', 'Email',
              'Date Hired', 'Regularization Date', 'Address', 'City', 'Plan Code',
              'For Card Issuance', 'Tin No', 'Philhealth', 'Philhealth No', 'Remarks'
            ]]
          else
            [[
              'Upload Status', 'Account Code', 'Employee No', 'Member Type', 'Relationship', 'Effective Date',
              'Expiry Date', 'First Name', 'Middle Name', 'Last Name', 'Suffix',
              'Gender', 'Civil Status', 'Birthdate', 'Mobile No', 'Email',
              'Date Hired', 'Regularization Date', 'Address', 'City', 'Plan Code',
              'For Card Issuance', 'Tin No', 'Philhealth', 'Philhealth No', 'Remarks'
            ]]
          end
        else
          if status == "success" do
            [[
              'Upload Status', 'Card No', 'Account Code', 'Principal Number', 'Member Type',
              'Relationship', 'Effective Date', 'Expiry Date',
              'First Name', 'Middle Name', 'Last Name', 'Suffix',
              'Gender', 'Civil Status', 'Birthdate', 'Mobile No', 'Email',
              'Address', 'City', 'Plan Code', 'For Card Issuance', 'Tin No',
              'Philhealth', 'Philhealth No', 'Remarks'
            ]]
          else
            [[
              'Upload Status', 'Account Code', 'Principal Number', 'Member Type', 'Relationship', 'Effective Date',
              'Expiry Date', 'First Name', 'Middle Name', 'Last Name', 'Suffix',
              'Gender', 'Civil Status', 'Birthdate', 'Mobile No', 'Email',
              'Address', 'City', 'Plan Code', 'For Card Issuance', 'Tin No',
              'Philhealth', 'Philhealth No', 'Remarks'
            ]]
          end
      end

      data =
        data ++ get_member_batch_log(log_id, status, type)
        |> CSV.encode
        |> Enum.to_list
        |> to_string

      conn
      |> json(data)
    end
  end

  def member_suspend(conn, %{"member" => params}) do
    member = MemberContext.get_member(params["member_id"])
    case MemberContext.suspend_member(member, params) do
      {:ok, member} ->
        if is_nil(member.suspend_date) do
          params = %{
            member_movement: "Suspension"
          }
          MemberContext.movement_member_log(
            conn.assigns.current_user,
            member,
            params,
            "retract"
          )
          conn
          |> put_flash(:info, "Successfully retracted movement.")
          |> redirect(to: "/members/#{member.id}")
        else
          params = %{
            suspension_reason: params["suspend_reason"],
            suspension_date: params["suspend_date"],
            suspension_remarks: params["suspend_remarks"]
          }
          MemberContext.movement_member_log(
            conn.assigns.current_user,
            member,
            params,
            "suspend"
          )
          conn
          |> put_flash(:info, "Member will be suspended on #{member.suspend_date}.")
          |> redirect(to: "/members/#{member.id}")
        end
      {:error, _error} ->
        conn
        |> put_flash(:error, "Failed to suspend member.")
        |> redirect(to: "/members/#{member.id}")
    end
  end

  def member_cancel(conn, %{"member" => params}) do
    member = MemberContext.get_member(params["member_id"])
    case MemberContext.cancel_member(member, params) do
      {:ok, member} ->
        if is_nil(member.cancel_date) do
          params = %{
            member_movement: "Cancellation"
          }
          MemberContext.movement_member_log(
            conn.assigns.current_user,
            member,
            params,
            "retract"
          )
          conn
          |> put_flash(:info, "Successfully retracted movement.")
          |> redirect(to: "/members/#{member.id}")
        else
          params = %{
            cancellation_reason: params["cancel_reason"],
            cancellation_date: params["cancel_date"],
            cancellation_remarks: params["cancel_remarks"]
          }
          MemberContext.movement_member_log(
            conn.assigns.current_user,
            member,
            params,
            "cancel"
          )
          conn
          |> put_flash(:info, "Member will be cancelled on #{member.cancel_date}.")
          |> redirect(to: "/members/#{member.id}")
        end
      {:error, _error} ->
        conn
        |> put_flash(:error, "Failed to cancel member.")
        |> redirect(to: "/members/#{member.id}")
    end
  end

  def member_reactivate(conn, %{"member" => params}) do
    member = MemberContext.get_member(params["member_id"])
    case MemberContext.reactivate_member(member, params) do
      {:ok, member} ->
        if is_nil(member.reactivate_date) do
          params = %{
            member_movement: "Reactivation"
          }
          MemberContext.movement_member_log(
            conn.assigns.current_user,
            member,
            params,
            "retract"
          )
          conn
          |> put_flash(:info, "Successfully retracted movement.")
          |> redirect(to: "/members/#{member.id}")
        else
          params = %{
            reactivation_reason: params["reactivate_reason"],
            reactivation_date: params["reactivate_date"],
            reactivation_remarks: params["reactivate_remarks"]
          }
          MemberContext.movement_member_log(
            conn.assigns.current_user,
            member,
            params,
            "reactivate"
          )
        conn
        |> put_flash(:info, "Member will be reactivated on #{member.reactivate_date}.")
        |> redirect(to: "/members/#{member.id}")
        end
      {:error, _error} ->
        conn
        |> put_flash(:error, "Failed to reactivate member.")
        |> redirect(to: "/members/#{member.id}")
    end
  end

  def skipping_hierarchy(conn, _params) do
    members = MemberContext.get_all_dependent_members()
    render(conn, "skipping_hierarchy.html", members: members)
  end

  #ajax for skipping hierarchy
  def approve_skipping_hierarchy(conn, %{"param" => params, "user_id" => user_id}) do
    for m_id <- params["member_id"] do
      MemberContext.approve_skipping_hierarchy(m_id, user_id)
    end
    conn
    |> json([])

    #skipped_dependents = get_all_skipping_hierarchy()
    #render(conn, "skipping.json", skipped_dependents: skipped_dependents)
  end

  def disapprove_skipping_hierarchy(conn, %{"param" => params, "user_id" => user_id, "reason" => reason}) do
    for m_id <- params["member_id"] do
      _skipped = MemberContext.disapprove_skipping_hierarchy(m_id, user_id, reason)
    end
    conn
    |> json([])

    #skipped_dependents = get_all_skipping_hierarchy()
    #render(conn, "skipping.json", skipped_dependents: skipped_dependents)
  end

  def download_skipping(conn, %{"skipping_param" => download_param, "type" => type}) do
    skipping = MemberContext.get_all_skipping_based_on_param(download_param, type)
    if type == "processed" do
      head = [["Member Name", "Account Name", "Principal Name", "Skipped Dependent", "Skipped Dependent's Relationship",
               "Birth Date", "Gender", "Reason for Skipping", "Date Requested", "Requested By", "Requested From", "Date Processed", "Processed By", "Status"]]
      data = for skip <- skipping do
        ["#{skip.member.first_name <> "  " <> skip.member.last_name}", "#{skip.member.account_group.name}", "#{skip.member.principal.first_name <> "  " <> skip.member.principal.last_name}", "#{skip.first_name <> "  " <> skip.last_name}", "#{skip.relationship}", "#{skip.birthdate}", "#{skip.gender}", "#{skip.reason}", "#{DateTime.to_date(skip.inserted_at)}", "#{skip.created_by.username}", "Payorlink", "#{DateTime.to_date(skip.updated_at)}", "#{skip.updated_by.username}", "#{skip.status}"]
      end
      download_data = head ++ data
                      |> CSV.encode
                      |> Enum.to_list
                      |> to_string
      conn
      |> json(download_data)
    else
      head = [["Member Name", "Account Name", "Principal Name", "Skipped Dependent", "Skipped Dependent's Relationship", "Birth Date", "Gender", "Reason for Skipping", "Date Requested", "Requested By", "Requested From"]]
      data = for skip <- skipping do
        ["#{skip.member.first_name <> "  " <> skip.member.last_name}", "#{skip.member.account_group.name}", "#{skip.member.principal.first_name <> "  " <> skip.member.principal.last_name}", "#{skip.first_name <> "  " <> skip.last_name}", "#{skip.relationship}", "#{skip.birthdate}", "#{skip.gender}", "#{skip.reason}", "#{DateTime.to_date(skip.inserted_at)} ", "#{skip.created_by.username}", "Payorlink"]
      end
      download_data = head ++ data
                      |> CSV.encode
                      |> Enum.to_list
                      |> to_string
      conn
      |> json(download_data)

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

  # for member_comments
  def create_member_comment(conn, %{"id" => id, "member_params" => params}) do
    case MemberContext.insert_single_comment(id, params, conn.assigns.current_user.id) do
      {:ok, member_comment} ->
        current_user = UserContext.get_user!(conn.assigns.current_user.id)
        json(conn, Poison.encode!(%{inserted_at: member_comment.inserted_at, comment: member_comment.comment,
          created_by: "#{current_user.first_name} #{current_user.last_name}"}))
      {:error, _changeset} ->
        conn
        |> put_status(400)
        |> json(Poison.encode!(%{error: true}))
    end
  end

  def edit_setup(conn, %{"id" => id, "tab" => tab}) do
    with {:true, id} <- UtilityContext.valid_uuid?(id),
         member = %Member{} <- MemberContext.get_member!(id) do
      case tab do
        "general" ->
          edit_general(conn, member)
        "products" ->
          edit_products(conn, member)
        "contact" ->
          edit_contact(conn, member)
        _ ->
          conn
          |> put_flash(:error, "Invalid tab")
          |> redirect(to: member_path(conn, :show, member))
      end
    else
      _ ->
        conn
        |> put_flash(:error, "Page not found")
        |> redirect(to: member_path(conn, :index))
    end
  end

  def edit_setup(conn, params), do: redirect_to_index(conn, "Page not found!")

  defp redirect_to_index(conn, message) do
    conn
    |> put_flash(:error, message)
    |> redirect(to: member_path(conn, :index))
  end

  def save(conn, %{"id" => id, "tab" => tab, "member" => member_params}) do
    member = MemberContext.get_member!(id)
    case tab do
      "general" ->
        update_general(conn, member, member_params)
      "products" ->
        update_products(conn, member, member_params)
      "contact" ->
        update_contact(conn, member, member_params)
      _ ->
        conn
        |> put_flash(:error, "Invalid tab")
        |> redirect(to: member_path(conn, :show, member))
    end
  end

  def edit_general(conn, member) do
    changeset = Member.changeset_general(member)
    render(conn, "edit/general.html", changeset: changeset, member: member)
  end

  def update_general(conn, member, member_params) do
    member_params =
      member_params
      |> translate_date_params()
      |> Map.put("updated_by_id", conn.assigns.current_user.id)
      |> Map.delete("effectivity_date")
    case update_member_general(member, member_params) do
      {:ok, member} ->
        if member_params["photo"] do
          update_member_photo(member, member_params)
        end
        if member_params["senior_photo"] do
          update_member_senior_photo(member, member_params)
        end
        if member_params["pwd_photo"] do
          update_member_pwd_photo(member, member_params)
        end
        conn
        |> put_flash(:success, "Successfully updated Member!")
        |> redirect(to: "/members/#{member.id}/edit?tab=general")
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error updating Member!")
        |> render("edit/general.html", changeset: changeset, member: member)
    end
  end

  def edit_products(conn, member) do
    render(conn, "edit/products.html", member: member)
  end

  def update_products(conn, member, member_params) do
    account_product_ids = String.split(member_params["account_product_ids_main"], ",")
    if account_product_ids == [""] do
      conn
      |> put_flash(:error, "Please select at least one plan!")
      |> render("edit/products.html", member: member)
    else
      case set_member_products(member, account_product_ids) do
        {:ok} ->
          conn
          |> put_flash(:info, "Successfully added plans")
          |> redirect(to: member_path(conn, :edit_setup, member, tab: "plan"))
        {:error} ->
          conn
          |> put_flash(:error, "You are only allowed to enter one plan with ACU Benefit.")
          |> render("edit/products.html", member: member)
        {:acu_mp_already_exist} ->
          conn
          |> put_flash(:error, "You are only allowed to enter one plan with ACU Benefit")
          |> render("edit/products.html", member: member)
      end
    end
  end

  def edit_contact(conn, member) do
    changeset = Member.changeset_general(member)
    render(conn, "edit/contact.html", changeset: changeset, member: member)
  end

  def update_contact(conn, member, member_params) do
    member_params = Map.put(member_params, "updated_by_id", conn.assigns.current_user.id)
    case update_member_contact(member, member_params) do
      {:ok, member} ->
        conn
        |> redirect(to: member_path(conn, :edit_setup, member, tab: "contact"))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit/contact.html", changeset: changeset, member: member)
    end
  end

  # def get_effective_date_by_product(conn, prod_code) do
  #   data = MemberContext.get_effective_data_by_product()
  #   render(conn, Innerpeace.PayorLink.Web.MemberView, "load_effective_date_by_prod", %{members: members})
  # end

  def generate_balancing_file(conn, params) do
    with true <- Map.has_key?(params, "month"),
         true <- Map.has_key?(params, "day"),
         true <- Map.has_key?(params, "hour"),
         true <- Map.has_key?(params, "minute")
    do
      schedule = %DateTime{
        year: 2018,
        month: String.to_integer(params["month"]),
        day: String.to_integer(params["day"]),
        zone_abbr: "SGT",
        hour: String.to_integer(params["hour"]),
        minute: String.to_integer(params["minute"]),
        second: 0,
        microsecond: {0, 0},
        utc_offset: 28_800,
        std_offset: 0,
        time_zone: "Singapore"
      }
      Exq.Enqueuer.start_link()

      Exq.Enqueuer
      |> Exq.Enqueuer.enqueue_at(
        "balancing_file_job",
        schedule,
        "Innerpeace.Worker.Job.BalancingFileJob",
        [123]
      )
      json(conn, Poison.encode!(%{valid: true}))
    else
      _ ->
        json(conn, Poison.encode!(%{valid: false}))
    end
  end

  def search_ag_member(conn, %{"params" => params}) do
    data = [['AccountGroup type', 'AccountGroup name',
             'AccountGroup code', 'Member type', 'Member first_name',
             'Member middle_name', 'Member last_name', 'Member card_no','Member status'
    ]] ++
      MemberContext.account_group_member_search(params)
      |> CSV.encode
      |> Enum.to_list
      |> to_string

    conn
    |> json(data)
  end

  def generate_claims_job(conn, _params) do
    {_, {year, month, day}} =
      Ecto.Date.utc()
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

    Exq.Enqueuer
    |> Exq.Enqueuer.enqueue_at(
      "trigger_generate_claims_file_job",
      schedule,
      "Innerpeace.Worker.Job.TriggerGenerateClaimsFileJob",
      []
    )
    json(conn, Poison.encode!("Claims file starts generating"))
  end

  defp translate_date_params(params) do
    params
    |> Map.put("birthdate", to_valid_date(params["birthdate"]))
    |> Map.put("date_hired", to_valid_date(params["date_hired"]))
    |> Map.put("regularization_date", to_valid_date(params["regularization_date"]))
    |> Map.put("effectivity_date", to_valid_date(params["effectivity_date"]))
    |> Map.put("expiry_date", to_valid_date(params["expiry_date"]))
  end

  defp to_valid_date(date) do
    UtilityContext.transform_string_dates(date)
  end

  def member_documents(conn, params) do
    conn
    |> json(%{
      data: MemberDatatable.member_document_data(
        params["start"],
        params["length"],
        params["search"]["value"],
        params["member_id"]),
      draw: params["draw"],
      recordsTotal: MemberDatatable.member_document_count(params["member_id"]),
      recordsFiltered: MemberDatatable.md_filtered_count(params["search"]["value"], params["member_id"])
    })
  end
end
