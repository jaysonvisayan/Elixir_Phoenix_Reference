defmodule AccountLinkWeb.MemberController do
  use AccountLinkWeb, :controller

  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.Db.Repo
  alias AccountLink.Guardian.Plug
  alias AccountLink.Guardian, as: AG

  alias Innerpeace.Db.Schemas.{
    Member,
    MemberComment,
    Peme,
    Facility
  }

  alias Innerpeace.Db.Base.{
    MemberContext,
    FacilityContext,
    AccountContext,
    CoverageContext,
    PackageContext,
    UserContext,
    AcuScheduleContext,
    ApiAddressContext,
    AuthorizationContext,
    PemeContext,
    Api.UtilityContext
  }

  alias Innerpeace.Db.Datatables.MemberDatatable
  alias Innerpeace.Db.Validators.PEMEValidator
  alias Innerpeace.PayorLink.Web.Api.V1.AuthorizationController, as: AP

  def index(conn, _params) do
    user = AG.current_resource(conn)
    user = Repo.preload(user, :user_account)
    if not is_nil(user.user_account) do
      id = user.user_account.account_group_id
      account_group = AccountContext.get_account_group(id)
      account = Enum.map(account_group.account, & (if &1.status == "Active", do: &1))
      account =
        account
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.first()
      # members = MemberContext.get_all_member_based_on_account(account_group.code)
      # MemberContext.activate_members()
      # member = update_member_status(members, account_group)
      # MemberContext.generate_evoucher(members, "account_link")
      changeset_cancel = Member.changeset_cancel(%Member{})
      changeset_suspend = Member.changeset_suspend(%Member{})
      changeset_reactivate = Member.changeset_reactivate(%Member{})
      render conn, "index.html", member: [],
        changeset_cancel: changeset_cancel,
        changeset_reactivate: changeset_reactivate,
        changeset_suspend: changeset_suspend,
        account: account
    else
      conn
      |> redirect(to: session_path(conn, :sign_in, conn.assigns.locale))
    end

  end

  def load_index(conn, params) do
    user = AG.current_resource(conn)
    user = Repo.preload(user, :user_account)
    id = user.user_account.account_group_id
    ag = AccountContext.get_account_group(id)
    count = MemberDatatable.accountlink_member_count(ag)
    data =
      params["start"]
      |> MemberDatatable.accountlink_member_data(
        params["length"],
        params["search"]["value"],
        ag,
        conn.assigns.locale
      )

    filtered_count =
      params["search"]["value"]
      |> MemberDatatable.accountlink_member_filtered_count(ag)

    conn
    |> json(%{
      data: data,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: filtered_count
    })
  end

  defp update_member_status(members, account_group) do
    for member <- members do
      if member.step >= 5 do
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
        if member.status == "For Renewal" or is_nil(member.status) or member.status == "" do
          MemberContext.active_member(member)
        end
      end
    end
    members = MemberContext.get_all_member_based_on_account(account_group.code)
  end

  def show(conn, %{"id" => id}) do
    member = MemberContext.get_member(id)
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
    if member.status == "Pending" or member.status == "For Renewal"
      or is_nil(member.status) or member.status == "" do
      MemberContext.active_member(member)
    end
    MemberContext.update_member_step(member, %{step: 5})
    member = MemberContext.get_member!(id)
    changeset = Member.changeset_movement(member, %{})
    render(conn, "show.html", member: member, changeset: changeset)
  end

  # for adding products on show page
  def add_member_product(conn, %{"id" => id, "member" => member_params}) do
    member = MemberContext.get_member(id)
    account_product_ids = String.split(member_params["account_product_ids_main"], ",")

    if account_product_ids == [""] do
      conn
      |> put_flash(:error, "Please select at least one product!")
      |> redirect(to: "/#{conn.assigns.locale}/members/#{member.id}/show")
    else
      case MemberContext.set_member_products(member, account_product_ids) do
        {:ok} ->
          MemberContext.add_member_product_log(conn.assigns.current_user, account_product_ids, member.id)
          conn
          |> put_flash(:info, "Successfully added plans")
          |> redirect(to: "/#{conn.assigns.locale}/members/#{member.id}/show")
        {:error} ->
          conn
          |> put_flash(:error, "You are only allowed to enter one plan with ACU Benefit.")
          |> redirect(to: "/#{conn.assigns.locale}/members/#{member.id}/show")
        {:acu_mp_already_exist} ->
          conn
          |> put_flash(:error, "You are only allowed to enter one plan with ACU Benefit")
          |> redirect(to: "/#{conn.assigns.locale}/members/#{member.id}/show")
      end
    end
  end

  # for saving product tier on show page
  def save_member_prduct_tier(conn, %{"id" => id, "member" => member_params}) do
    member = MemberContext.get_member(id)
    member_product_tier = member_params["product_tier"]
    if member_product_tier == "" do
      conn
      |> redirect(to: "/#{conn.assigns.locale}/members/#{member.id}/show")
    else
      MemberContext.show_update_product_tier(member_product_tier
      |> String.split(","), member, conn.assigns.current_user)

      conn
      |> put_flash(:info, "Successfully updated plan tier")
      |> redirect(to: "/#{conn.assigns.locale}/members/#{member.id}/show")
    end
  end

  def new(conn, _params) do
    user = conn.assigns.current_user
    user = Repo.preload(user, :user_account)
    account_group_id = user.user_account.account_group_id
    account_group = AccountContext.get_account_group(account_group_id)
    changeset = Member.changeset_general(%Member{})

    render conn, "enroll_1.html",
      action: member_path(conn, :create_general, conn.assigns.locale),
      account_group: account_group, changeset: changeset
  end

  def create_general(conn, %{"member" => member_params}) do
    # member_params = setup_civil_status(member_params)
    account_group = AccountContext.get_account_group(member_params["account_group_id"])
    card_no = MemberContext.member_card_checker("1168011034280092")
    member_params =
      member_params
      |> Map.put("card_no", card_no)
      |> Map.put("step", 2)
      |> Map.put("created_by_id", conn.assigns.current_user.id)

    with {:ok, member} <- MemberContext.create_member(member_params)
    do
      if member_params["photo"] do
        MemberContext.update_member_photo(member, member_params)
      end
      if member_params["senior_photo"] do
        MemberContext.update_member_senior_photo(member, member_params)
      else
        MemberContext.update_member_senior_photo(member, %{"senior_photo" => nil})
      end
      if member_params["pwd_photo"] do
        MemberContext.update_member_pwd_photo(member, member_params)
      else
        MemberContext.update_member_pwd_photo(member, %{"pwd_photo" => nil})
      end
      if member_params["skipping_hierarchy"] != [""] do
        MemberContext.update_for_approval_status(member)
        MemberContext.insert_member_hierarchy(member.id, conn.assigns.current_user.id, member_params["skipping_hierarchy"])
      end

      conn
      |> redirect(to: "/#{conn.assigns.locale}/members/#{member.id}/setup?step=2")
    else
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Employee number is already used within the account!")
        |> render("enroll_1.html", action: member_path(conn, :create_general,
                                                       conn.assigns.locale),
                  account_group: account_group, changeset: changeset)
    end
  end

  defp setup_civil_status(params) do
    with "Dependent" <- params["type"] do
      case params["relationship"] do
        "Spouse" ->
          Map.put(params, "civil_status", "Married")
        "Parent" ->
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
        |> redirect(to: member_path(conn, :index, conn.assigns.locale))
    end
  end

  def edit(conn, %{"id" => id, "step" => step}) do
    member = MemberContext.get_member!(id)
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
        |> redirect(to: member_path(conn, :index, conn.assigns.locale))
    end
  end

  def edit(conn, %{"id" => id}) do
    conn
    |> put_flash(:error, "Invalid step!")
    |> redirect(to: member_path(conn, :index, conn.assigns.locale))
  end

  def update_setup(conn, %{"id" => id, "step" => step, "member" => member_params}) do
    member = MemberContext.get_member!(id)

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
        |> redirect(to: member_path(conn, :index, conn.assigns.locale))
    end
  end

  defp redirect_step(conn, member_id, current_step, next_step, save_step) do
    if save_step == 5 do
      conn
      |> redirect(to: "/#{conn.assigns.locale}/members/#{member_id}/show")
    else
      conn
      |> redirect(to: "/#{conn.assigns.locale}/members/#{member_id}/setup?step=#{next_step}")
    end
  end

  def step1(conn, member) do
    user = conn.assigns.current_user
    user = Repo.preload(user, :user_account)
    account_group_id = user.user_account.account_group_id
    account_group = AccountContext.get_account_group(account_group_id)
    changeset = Member.changeset_general(member)

    render conn, "enroll_1.html",
      action: member_path(conn, :update_setup, conn.assigns.locale,
                        member, step: "1"),
      account_group: account_group, changeset: changeset, member: member
  end

  def step1_update(conn, member, member_params) do
    account_group =
      AccountContext.get_account_group(member_params["account_group_id"])
    member_params = update_step1_member_params(conn, member_params)

    with {:ok, _updated_member} <- MemberContext.update_member_general(
      member,  member_params
    )
    do
      # MemberContext.clear_member_products(member.id)
      if member_params["photo"] do
        MemberContext.update_member_photo(member, member_params)
      end
      if member_params["senior_photo"] do
        MemberContext.update_member_senior_photo(member, member_params)
      else
        MemberContext.update_member_senior_photo(member, %{
          "senior_photo" => nil
        })
      end
      if member_params["pwd_photo"] do
        MemberContext.update_member_pwd_photo(member, member_params)
      else
        MemberContext.update_member_pwd_photo(member, %{
          "pwd_photo" => nil
        })
      end
      if member_params["skipping_hierarchy"] != [""] do
        MemberContext.update_for_approval_status(member)
        MemberContext.insert_member_hierarchy(
          member.id,
          conn.assigns.current_user.id,
          member_params["skipping_hierarchy"]
        )
      else
        MemberContext.delete_skipping_for_edit(member.id)
        MemberContext.update_status_to_nil(_updated_member)
      end

      if _updated_member.step == 5 do
        MemberContext.logs_for_edit_member(
          conn.assigns.current_user,
          member,
          Member.changeset_general(member, member_params),
          "General"
        )
        conn = put_flash(conn, :info, "Member info successfully updated.")
      end
      redirect_step(conn, _updated_member.id, 1, 2, _updated_member.step)
    else
      {:error, changeset} ->
        conn
        |> put_flash(:error,
                     "Employee number is already used within the  account!")
        |> render("enroll_1.html",
                  action: member_path(conn, :update_setup,
                                      conn.assigns.locale,
                                      member, step: "1"
                  ),
                  changeset: changeset,
                  account_group: account_group,
                  member: member)
    end
  end

  defp update_step1_member_params(conn, member_params) do
    if member_params["type"] == "Principal" do
      member_params = Map.put(member_params, "principal_id", "")
    end

    member_params = Map.put(member_params, "updated_by_id",
                            conn.assigns.current_user.id)
    philhealth = member_params["philhealth"]

    philhealth =
      if philhealth do
        String.replace(philhealth, "-", "")
      end
    tin = member_params["tin"]

    tin =
      if tin do
        String.replace(tin, "-", "")
      end

    member_params = Map.merge(member_params, %{
      "philhealth" => philhealth,
      "tin" => tin})

    if member_params["senior"] do
      if member_params["senior_id"] do
        senior_id = member_params["senior_id"]
      else
        senior_id = ""
      end
      member_params = Map.merge(member_params, %{"senior_id" => senior_id})
    else
      member_params = Map.merge(member_params, %{"senior_id" => ""})
    end

    if member_params["pwd"] do
      if member_params["pwd_id"] do
        pwd_id = member_params["pwd_id"]
      else
        pwd_id = ""
      end
      member_params = Map.merge(member_params, %{"pwd_id" => pwd_id})
    else
      member_params = Map.merge(member_params, %{"pwd_id" => ""})
    end
  end

  def step2(conn, member) do
    render(conn, "enroll_2.html", member: member)
  end

  def step2_update(conn, member, member_params) do
    account_product_ids =
      String.split(member_params["account_product_ids_main"], ",")

    if account_product_ids == [""] do
      conn
      |> put_flash(:error, "Please select at least one product!")
      |> render("enroll_2.html", member: member)
    else
      if member.step != 5 do
        MemberContext.update_member_step(member, %{
          "step" => 3,
          "updated_by_id" => conn.assigns.current_user.id
        })
      end

      with {:ok} <- MemberContext.set_member_products(member, account_product_ids)
      do
        if member.step == 5 do
          MemberContext.add_member_product_log(conn.assigns.current_user, account_product_ids, member.id)
          conn
          |> put_flash(:info, "Member's product/s successfully updated.")
          |> redirect_step(member.id, 2, 3, member.step)
        else
          conn
          |> put_flash(:info, "Successfully added plan/s")
          |> redirect_step(member.id, 2, 2, member.step)
        end
      else
        {:error} ->
          conn
          |> put_flash(:error, "You are only allowed to enter one plan with ACU Benefit.")
          |> render("enroll_2.html", member: member)
        {:acu_mp_already_exist} ->
          conn
          |> put_flash(:error, "You are only allowed to enter one plan with ACU Benefit")
          |> render("enroll_2.html", member: member)
      end
    end
  end

  def step2_update_tier(conn, member, member_params) do
    member_product_tier = member_params["product_tier"]
    if member_product_tier == "" do
      conn
      |> redirect(to: "/#{conn.assigns.locale}/members/#{member.id}/setup?step=3")
    else
      MemberContext.update_product_tier(member_product_tier |> String.split(","))
      conn
      |> redirect(to: "/#{conn.assigns.locale}/members/#{member.id}/setup?step=3")
    end
  end

  def step3(conn, member) do
    changeset = Member.changeset_contact(member)
    render(conn, "enroll_3.html", member: member, changeset: changeset)
  end

  def step3_update(conn, member, member_params) do
    if member.step < 5 do
      member_params = Map.put(member_params, "step", 4)
    end
    member_params = Map.put(member_params, "updated_by_id",
                            conn.assigns.current_user.id)

    mobile = String.replace(member_params["mobile"], "-", "")
    mobile2 = member_params["mobile2"]
    mobile2 =
      if mobile2 do
        String.replace(mobile2, "-", "")
      end
    telephone = member_params["telephone"]
    telephone =
      if telephone do
        String.replace(telephone, "-", "")
      end
    fax = member_params["fax"]
    fax =
      if fax do
        String.replace(fax, "-", "")
      end

    member_params = Map.merge(member_params, %{
      "mobile" => mobile,
      "mobile2" => mobile2,
      "telephone" => telephone,
      "fax" => fax})

    with {:ok, _updated_member} <- MemberContext.update_member_contact(member, member_params)
    do
      if _updated_member.step == 5 do
        MemberContext.logs_for_edit_member(
          conn.assigns.current_user,
          member,
          Member.changeset_contact(member, member_params),
          "Contact"
        )
        conn = put_flash(conn, :info, "Member's contact successfully updated.")
      end
      redirect_step(conn, member.id, 3, 4, _updated_member.step)
    else
      {:error, changeset} ->
        conn
        |> render("enroll_3.html", member: member, changeset: changeset)
    end
  end

  def step4(conn, member) do
    render(conn, "enroll_4.html", member: member)
  end

  def step4_update(conn, member, _member_params) do
    MemberContext.update_member_step(member, %{
      "step" => 5,
      "updated_by_id" => conn.assigns.current_user.id})
    MemberContext.create_member_log(
      conn.assigns.current_user,
      member
    )

    if member.step == 5 do
      conn
      |> put_flash(:info, "Member's info successfully updated.")
      |> redirect_step(member.id, 4, 4, member.step)
    else
      conn
      |> render("enroll_4.html", modal_open: true, member: member)
    end
  end

  # Member Movement
  def member_cancel(conn, %{"member" => params}) do
    if params["cancel_date"] == "for_retract" do
      params = Map.drop(params, ["cancel_date", "cancel_reason", "cancel_remarks"])
      params = Map.merge(params, %{
        "cancel_date" => "",
        "cancel_reason" => "",
        "cancel_remarks" => ""})
    end

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
          |> redirect(to: member_path(conn, :index, conn.assigns.locale))
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
          |> redirect(to: member_path(conn, :index, conn.assigns.locale))
        end
      {:error, _error} ->
        conn
        |> put_flash(:error, "Failed to cancel member.")
        |> redirect(to: member_path(conn, :index, conn.assigns.locale))
    end
  end

  def member_suspend(conn, %{"member" => params}) do
    if params["suspend_date"] == "for_retract" do
      params = Map.drop(params, ["suspend_date", "suspend_reason", "suspend_remarks"])
      params = Map.merge(params, %{
        "suspend_date" => "",
        "suspend_reason" => "",
        "suspend_remarks" => ""})
    end

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
          |> redirect(to: member_path(conn, :index, conn.assigns.locale))
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
          |> redirect(to: member_path(conn, :index, conn.assigns.locale))
        end
      {:error, _error} ->
        conn
        |> put_flash(:error, "Failed to suspend member.")
        |> redirect(to: member_path(conn, :index, conn.assigns.locale))
    end
  end

  def member_reactivate(conn, %{"member" => params}) do
    if params["reactivate_date"] == "for_retract" do
      params = Map.drop(params, ["reactivate_date", "reactivate_reason", "reactivate_remarks"])
      params = Map.merge(params, %{
        "reactivate_date" => "",
        "reactivate_reason" => "",
        "reactivate_remarks" => ""})
    end

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
          |> redirect(to: member_path(conn, :index, conn.assigns.locale))
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
          |> redirect(to: member_path(conn, :index, conn.assigns.locale))
        end
      {:error, _error} ->
        conn
        |> put_flash(:error, "Failed to reactivate member.")
        |> redirect(to: member_path(conn, :index, conn.assigns.locale))
    end
  end
  #End of Member Movement

  #batch processing
  def batch_processing_index(conn, _params) do
    user = AG.current_resource(conn)
    user = Repo.preload(user, :user_account)
    account_group_id = user.user_account.account_group_id
    users = UserContext.get_users_by_account(account_group_id)
    member_upload_files = MemberContext.get_member_upload_files_by_created_by(users)
    render(conn, "import_index.html", member_upload_files: member_upload_files)
  end

  def import_member(conn, %{"member" => member_params}) do
    if is_nil(member_params["file"]) or member_params["file"] == "" do
      conn
      |> put_flash(:error, "Please choose a file.")
      |> redirect(to: "/#{conn.assigns.locale}/members/batch_processing")
    else
      user_id = conn.assigns.current_user.id
      create_member_import(conn, member_params, user_id)
    end
  end

  defp create_member_import(conn, member_params, user_id) do
    case MemberContext.create_member_import_account_link(member_params, user_id) do
      {:ok} ->
        conn
        |> put_flash(:info, "Batch successfully uploaded.")
        |> redirect(to: "/#{conn.assigns.locale}/members/batch_processing")
      {:not_found} ->
        conn
        |> put_flash(:error, "File uploaded is empty.")
        |> redirect(to: "/#{conn.assigns.locale}/members/batch_processing")
      {:not_equal} ->
        conn
        |> put_flash(:error, "Invalid column format")
        |> redirect(to: "/#{conn.assigns.locale}/members/batch_processing")
      {:not_equal, columns} ->
        conn
        |> put_flash(:error, "File has missing column/s: #{columns}")
        |> redirect(to: "/#{conn.assigns.locale}/members/batch_processing")
      {:invalid_format} ->
        conn
        |> put_flash(:error, "Acceptable files is .csv")
        |> redirect(to: "/#{conn.assigns.locale}/members/batch_processing")
      {:error_user} ->
        conn
        |> put_flash(:error, "Error There's no Account in current user")
        |> redirect(to: "/#{conn.assigns.locale}/members/batch_processing")
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Oops, something went wrong.")
        |> redirect(to: "/#{conn.assigns.locale}/members/batch_processing")
    end
  end

  def validate_member_info(conn, %{"member" => _params}) do
    # raise params
    render conn
  end

  # def add_skipping(conn, %{"id" => id, "skip" => params}) do
  #   render conn
  # end

  # JSON
  def download_members(conn, %{"member_param" => download_param}) do
    data = [["Member ID", "Member Name", "Card Number", "Status"]] ++
      MemberContext.export_members(download_param)
      |> CSV.encode
      |> Enum.to_list
      |> to_string

    conn
    |> json(data)
  end

  def member_batch_download(conn, %{"log_id" => log_id, "status" => status, "type" => type}) do
    case type do
      "Corporate" ->
        if status == "success" do
        data = [[
          'Upload Status', 'Card No', 'Account Code', 'Employee No',
          'Member Type', 'Relationship', 'Effective Date', 'Expiry Date',
          'First Name', 'Middle Name', 'Last Name', 'Suffix',
          'Gender', 'Civil Status', 'Birthdate',
          'Mobile No', 'Email', 'Date Hired', 'Regularization Date',
          'Address', 'City', 'Plan Code', 'For Card Issuance',
          'Tin No', 'Philhealth', 'Philhealth No', 'Remarks'
        ]] ++
          MemberContext.get_member_batch_log(log_id, status, type)
          |> CSV.encode
          |> Enum.to_list
          |> to_string

          conn
          |> json(data)
        else
        data = [[
          'Upload Status', 'Account Code', 'Employee No', 'Member Type',
          'Relationship', 'Effective Date', 'Expiry Date',
          'First Name', 'Middle Name', 'Last Name', 'Suffix',
          'Gender', 'Civil Status', 'Birthdate',
          'Mobile No', 'Email', 'Date Hired', 'Regularization Date',
          'Address', 'City', 'Plan Code', 'For Card Issuance',
          'Tin No', 'Philhealth', 'Philhealth No', 'Remarks'
        ]] ++
          MemberContext.get_member_batch_log(log_id, status, type)
          |> CSV.encode
          |> Enum.to_list
          |> to_string

          conn
          |> json(data)
        end
      "Cancellation" ->
        data = [[
          'Remarks', 'Member ID', 'Cancellation Date', 'Reason'
        ]] ++
          MemberContext.get_member_maintenance_batch_log(log_id, status)
          |> CSV.encode
          |> Enum.to_list
          |> to_string

          conn
          |> json(data)
      "Suspension" ->
        data = [[
          'Remarks', 'Member ID', 'Suspension Date', 'Reason'
        ]] ++
          MemberContext.get_member_maintenance_batch_log(log_id, status)
          |> CSV.encode
          |> Enum.to_list
          |> to_string

          conn
          |> json(data)
      "Reactivation" ->
        data = [[
          'Remarks', 'Member ID', 'Reactivation Date', 'Reason'
        ]] ++
          MemberContext.get_member_maintenance_batch_log(log_id, status)
          |> CSV.encode
          |> Enum.to_list
          |> to_string

          conn
          |> json(data)
    end
  end

  def delete_member_product(conn, %{"member_id" => member_id, "id" => member_product_id}) do
    member = MemberContext.get_member!(member_id)
    member_product = MemberContext.get_member_product(member_product_id) |> List.first()
    authorization_member_product = MemberContext.get_authorization_member_products(member_product_id)

    with true <- Enum.empty?(authorization_member_product),
         {:ok} <- MemberContext.check_acu_loa_by_member(member.id)
    do
      account_product_id = member_product.account_product.id
      MemberContext.delete_member_account_product(member.id, member_product_id)
      if member.step >= 5 do
        MemberContext.delete_member_product_log(conn.assigns.current_user, account_product_id, member_id)
      end
      json conn, Poison.encode!(%{valid: true})
    else
      false ->
        json conn, Poison.encode!(%{valid: false, coverage: "other"})
      {:error} ->
        json conn, Poison.encode!(%{valid: false, coverage: "ACU"})
    end
  end

  def delete_member_photo(conn, %{"id" => member_id}) do
    member = MemberContext.get_member!(member_id)
    MemberContext.update_member_photo(member, %{"photo" => nil})
    json conn, Poison.encode!("true")
  end

  def create_member_comment(conn, %{"id" => id, "member_params" => params}) do
   case MemberContext.insert_single_comment(
     id,
     params,
     conn.assigns.current_user.id)
    do
      {:ok, member_comment} ->
        current_user = UserContext.get_user!(conn.assigns.current_user.id)
        json(conn, Poison.encode!(
          %{
            inserted_at: member_comment.inserted_at,
            comment: member_comment.comment,
            created_by: "#{current_user.first_name} #{current_user.last_name}"
          }
        ))
      {:error, _changeset} ->
        conn
        |> put_status(400)
        |> json(Poison.encode!(%{error: true}))
    end
  end

  # member logs
  def get_member_logs(conn, %{"id" => id}) do
    logs = MemberContext.get_member_logs(id)
    render(conn, AccountLinkWeb.MemberView, "member_logs.json", logs: logs)
  end

  # Evoucher Functions

  def evoucher_index(conn, _) do
    changeset = Member.changeset_general(%Member{})
    conn
    |> render("evoucher/index.html", changeset: changeset)
  end

  def validate_evoucher(conn, %{"evoucher" => evoucher, "locale" => locale}) do
    case MemberContext.validate_evoucher(evoucher["evoucher"]) do
      {:ok, member_id} ->
        conn
        |> redirect(
          to: "/#{locale}/validate_evoucher/#{member_id}"
        )
      {:error} ->
        changeset = Member.changeset_general(%Member{})
        conn
        |> put_flash(:error, "E-voucher Number is invalid")
        |> render("evoucher/index.html", changeset: changeset)
        {:error_loa} ->
          changeset = Member.changeset_general(%Member{})
          conn
          |> put_flash(:error, "E-voucher already has a Letter of Authorization (LOA)")
          |> render("evoucher/index.html", changeset: changeset)
        {:invalid, message} ->
          changeset = Member.changeset_general(%Member{})
          conn
          |> put_flash(:error, message)
          |> render("evoucher/index.html", changeset: changeset)
    end
  end

  # defp request_peme_loa_providerlink(conn, params, evoucher) do
  #   peme =
  #     params.member.peme
  #     |> Repo.preload(:account_group)

  #   with {:ok, token} <- AcuScheduleContext.providerlink_sign_in_v2() do
  #     api_address = ApiAddressContext.get_api_address_by_name("PROVIDERLINK_2")
  #     providerlink_url = "#{api_address.address}/api/v1/peme/insert_loa"
  #     headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
  #     param =
  #         params
  #         |> Map.put(:evoucher, evoucher)
  #         |> Map.put(:account_code, peme.account_group.code)

  #     body = create_json_params(param)
  #     HTTPoison.post(providerlink_url, body, headers)
  #     with {:ok, response} <- HTTPoison.post(providerlink_url, body, headers) do
  #       resp = Poison.decode!(response.body)
  #       if resp["message"] == "Succesfully Created Peme Loa" do
  #         {:ok, response}
  #       else
  #         AuthorizationContext.delete_authorization_peme_accountlink(params.authorization_id)
  #         MemberContext.update_peme_status(peme, %{status: "Pending", registration_date: nil})
  #         {:error, "Error creating loa in providerlink."}
  #       end
  #     else
  #       _ ->
  #         AuthorizationContext.delete_authorization_peme_accountlink(params.authorization_id)
  #         MemberContext.update_peme_status(peme, %{status: "Pending", registration_date: nil})
  #         {:error}
  #     end

  #   else
  #   _ ->
  #       AuthorizationContext.delete_authorization_peme_accountlink(params.authorization_id)
  #       MemberContext.update_peme_status(peme, %{status: "Pending", registration_date: nil})
  #      {:unable_to_login, "Unable to login to ProviderLink API"}
  #    end
  # end

  # defp create_json_params(params) do
  #   {_, package_name} = Enum.at(params.package, 2)
  #   loa_number = AuthorizationContext.get_loa_number_by_loa_id(params.authorization_id)
  #   account_name = MemberContext.get_member_account_name_by_code(params.account_code)
  #   male = if params.member.gender == "Male", do: true, else: false
  #   female = if params.member.gender == "Female", do: true, else: false

  #   params = %{
  #     "facility_id" => params.facility_id,
  #     "first_name" => params.member.first_name,
  #     "middle_name" => params.member.middle_name,
  #     "last_name" => params.member.last_name,
  #     "suffix" => params.member.suffix,
  #     "birthdate" => params.member.birthdate,
  #     "card_no" => params.member.card_no,
  #     "id" => params.member.id,
  #     "male" => male,
  #     "female" => female,
  #     "member_status" => "Active",
  #     "email" => params.member.email,
  #     "mobile" => params.member.mobile,
  #     "evoucher_number" => params.evoucher,
  #     "type" => params.member.type,
  #     "account_code" => params.member.account_code,
  #     "package_facility_rate" => params.package_facility_rate,
  #     "authorization_id" => params.authorization_id,
  #     "number" => loa_number,
  #     "evoucher" => params.evoucher,
  #     "account_name" => account_name,
  #     "gender" => params.member.gender,
  #     # loa_packages
  #     "benefit_package_id" => params.benefit_package_id,
  #     "package_name" => package_name,
  #     # "package_code" => package_code,
  #     "benefit_code" => params.benefit_code,
  #     "payor_procedure" => params.payor_procedure,
  #     "package_facility_rate" => params.package_facility_rate,
  #     "admission_date" => params.admission_date,
  #     "discharge_date" => params.discharge_date

  #   }|> Poison.encode!()
  # end

  def edit_evoucher_facility(conn, %{"id" => id}) do
    coverage = CoverageContext.get_coverage_by_code("ACU")
    peme = MemberContext.get_peme(id)
    member = MemberContext.get_member(peme.member_id)
    changeset = Peme.changeset_facility(%Peme{}, %{})
    product_codes = Enum.map(member.products, &(&1.account_product.product.code))

    if not is_nil(peme.facility_id) do
      facilities = peme_facility_checker(peme.facility_id)
    else
      facilities = peme_facility_checker(product_codes, peme.package_id)
    end

    cond do
      peme.status == "Issued" or peme.status == "Pending" ->
        changeset = Member.changeset_update_evoucher(member)
      conn
      |> render(
        "evoucher/edit_facility.html",
        changeset: changeset,
        peme: peme,
        facilities: Poison.encode!(facilities),
        evoucher: peme.evoucher_number,
        locale: conn.assigns.locale
      )
      peme.status == "Cancelled" ->
        conn
        |> put_flash(:error, "Member is Already Cancelled")
        |> redirect(
          to: "/#{conn.assigns.locale}/peme/#{id}/show"
        )
      peme.status == "Registered" ->
        conn
        |> put_flash(:error, "Member is Already Registered")
        |> redirect(
          to: "/#{conn.assigns.locale}/peme/#{id}/show"
        )
      true ->
        conn
        |> redirect(
          to: "/#{conn.assigns.locale}/peme/#{id}/show"
        )
    end
  end

  defp peme_facility_checker(facility_id) do
    AcuScheduleContext.get_peme_facilities(facility_id)
  end

  defp peme_facility_checker(product_codes, package_id) do
    AcuScheduleContext.get_peme_facilities(product_codes, package_id)
  end

  def update_evoucher_facility(conn, params) do
    peme = MemberContext.get_peme(params["id"])
    changeset = Peme.changeset_facility(%Peme{}, %{})
    peme_params = params["peme"]

    case MemberContext.update_peme_facility(peme, peme_params["facility_id"]) do
      {:ok, peme} ->
        facility = FacilityContext.get_facility(peme_params["facility_id"])

        MemberContext.update_evoucher_member_status(peme.member.id, %{status: "Active"})
        registered_date = Ecto.DateTime.from_erl(:calendar.now_to_datetime(:erlang.now))
        MemberContext.update_peme_status(peme, %{status: "Registered", registration_date: registered_date})

        peme_facility = facility.code
        {_, date_from} = Ecto.Date.to_string(peme.date_from) <> " 00:00:00"
                          |> Ecto.DateTime.cast()

        {_, date_to} = Ecto.Date.to_string(peme.date_to) <> " 00:00:00"
                        |> Ecto.DateTime.cast()

        rp_params = %{
          "origin" => "Accountlink",
          "member_id" => peme.member_id,
          "facility_code" => peme_facility,
          "card_no" => peme.member.card_no,
          "coverage_code" => "PEME",
          "evoucher" => peme.evoucher_number,
          "admission_datetime" => Ecto.Date.to_string(peme.date_from),
          "discharge_datetime" => Ecto.Date.to_string(peme.date_to),
        }

        user = conn.assigns.current_user
        with {:ok, response} <- PemeContext.request_peme(conn, rp_params, user) do
          conn
          |> put_flash(:info, "Pre-employment Medical Examination Application form Submitted")
          |> redirect(
            to: "/#{conn.assigns.locale}/peme/#{peme.id}/evoucher_summary"
          )
        else
          {:error, message} ->
            MemberContext.update_peme_status_pending(peme)
            conn
            |> put_flash(:error, message)
            |> redirect(
              to: "/#{conn.assigns.locale}/peme/#{peme.id}/show"
            )
          _ ->
            conn
            |> put_flash(:error, "Error creating loa")
            |> redirect(
              to: "/#{conn.assigns.locale}/members/evoucher/#{peme.id}/facility_edit"
            )
        end

      {:error, changeset} ->
        MemberContext.update_peme_status_pending(peme)
        conn
        |> put_flash(:error, "Please check your inputs")
        |> redirect(
          to: "/#{conn.assigns.locale}/members/evoucher/#{peme.id}/facility_edit"
        )
    end
  end

  defp request_peme_loa_2(conn, rp_params) do
    with {:ok, token} <- UtilityContext.payorlink_v2_sign_in() do
      api_address = ApiAddressContext.get_api_address_by_name("PAYORLINK_2")
      payorlink_url = "#{api_address.address}/api/v1/loa/details/peme/get_all_details"
      headers = [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
      body = Poison.encode!(rp_params)

      with {:ok, response} <- HTTPoison.post(payorlink_url, body, headers, []) do
        if response.status_code == 200 do
          {:ok, response}
        else
          resp = Poison.decode!(response.body)
          message = resp["message"]
          {:error_login_api, message}
        end

      else
        {:unable_to_login, "Error occurs when attempting to login in Payorlink"} ->
          {:unable_to_login_payorlink_api}

        _ ->
          {:unable_to_sign_in_payorlink}
      end

    else
      _ ->
        {:unable_to_sign_in_payorlink, "Error: Sign-in Payorlink"}
    end
  end

  def get_senior_id(conn, _params) do
    members = MemberContext.get_senior_id()
    json conn, Poison.encode!(members)
  end

  def get_mobile_number(conn, %{"mobile" => mobile}) do
    m_number = MemberContext.get_mobile_number(mobile)
    json conn, Poison.encode!(m_number)
  end

  def get_pwd_id(conn, _params) do
    members = MemberContext.get_pwd_id()
    json conn, Poison.encode!(members)
  end
  # End JSON

  #private function for peme
  defp get_facility_filter_from_account(account, coverage) do
    products = get_product_from_account(account)
    facilities_id =
      for product <- products do
        for product_coverage <- product.product_coverages do
          if product_coverage.coverage_id == coverage.id do
            if product_coverage.type == "inclusion" do
              Enum.map(product_coverage.product_coverage_facilities, & (&1.facility.id))
            else
              get_all_facility_id -- Enum.map(product_coverage.product_coverage_facilities, & (&1.facility.id))
            end
          end
        end
      end
    facilities_id =
      facilities_id
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
    facilities =
      Facility
      |> where([f], f.id in ^facilities_id)
      |> where([f], f.step > 6 and f.status == "Affiliated")
      |> order_by([f], asc: f.name)
      |> Repo.all()
      |> Enum.uniq()
      |> List.delete(nil)
  end

  defp get_product_from_account(account) do
    product =
      Enum.map(account.account_products, & (if &1.product.product_category == "PEME Product", do: &1.product))
    product =
      product
      |> Enum.uniq()
      |> List.delete(nil)
  end

  defp get_all_facility_id do
    Facility
    |> select([f], f.id)
    |> Repo.all()
  end

  defp filter_facilities(facilities) do
    Enum.map(facilities, &(&1.id))
  end

  defp filter_facilities_by_package(package, facility_ids) do
    facilities =
      Enum.map(package.package_facility, & (if Enum.member?(facility_ids, &1.facility.id), do:
      %{
        "id" => &1.facility.id,
        "code" => &1.facility.code,
        "name" => &1.facility.name,
        "title" => &1.facility.code <> " | " <> &1.facility.name,
        "line_1" => &1.facility.line_1,
        "line_2" => &1.facility.line_2,
        "city" => &1.facility.city,
        "province" => &1.facility.province,
        "region" => &1.facility.region,
        "country" => &1.facility.country,
        "postal_code" => &1.facility.postal_code,
        "phone_no" => &1.facility.phone_no,
        "latitude" => &1.facility.latitude,
        "longitude" => &1.facility.longitude,
        "logo" => &1.facility.logo
      }
      ))
      facilities
      |> Enum.uniq()
      |> List.delete(nil)
  end
end
