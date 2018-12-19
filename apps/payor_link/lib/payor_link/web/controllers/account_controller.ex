defmodule Innerpeace.PayorLink.Web.AccountController do
  use Innerpeace.PayorLink.Web, :controller
  alias Phoenix.View
  alias Innerpeace.PayorLink.Web.AccountView
  alias Innerpeace.Db.Base.{
    AccountContext,
    ClusterContext,
    ContactContext,
    CoverageContext,
    Api.UtilityContext,
    ProductContext
  }

  alias Innerpeace.Db.Schemas.{
    Account,
    AccountGroup,
    AccountGroupCoverageFund,
    AccountGroupAddress,
    AccountProduct,
    Contact,
    PaymentAccount,
    Bank,
    AccountComment
  }

  alias Innerpeace.Db.Datatables.AccountDatatable

  plug :valid_uuid?, %{origin: "accounts"}
  when not action in [:index]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{accounts: [:manage_accounts]},
       %{accounts: [:access_accounts]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [%{accounts: [:manage_accounts]}
     ]] when not action in [
       :index,
       :show,
       :account_index,
       :index_versions,
       :download_account,
       # :print_account
     ]

  # Setup
  def setup(conn, %{"id" => id, "step" => step}) do
    case AccountContext.get_account!(id) do
      %Account{} ->
        account = AccountContext.get_account!(id)
        validate_step(conn, account, step)

        case step do
          "1" ->
            step_general(conn, account)
          "2" ->
            step_address(conn, account)
          "3" ->
            step_contact(conn, account)
          "4" ->
            validate_contact(conn, account)
          "5" ->
            step_hoed(conn, account)
          "6" ->
            step_summary(conn,  account)
          _ ->
            conn
            |> put_flash(:error, "Invalid step!")
            |> redirect(to: account_path(conn, :index))
        end
      _ ->
        data_is_nil(conn, "Account not found.")
    end
  end

  def setup(conn, _), do: data_is_nil(conn, "Page not found.")

  defp validate_contact(conn, account) do
    ag_id =  account.account_group_id
    corp_signatory = contact_type(ag_id, "Corp Signatory")
    contact_person = contact_type(ag_id, "Contact Person")
    account_officer = contact_type(ag_id, "Account Officer")

    cond do
      corp_signatory == 0 ->
        conn
        |> put_flash(:error, "At least one Corp Signatory is required")
        |> redirect(to: "/accounts/#{account.id}/setup?step=3")
      contact_person == 0 ->
        conn
        |> put_flash(:error, "At least one Contact Person is required")
        |> redirect(to: "/accounts/#{account.id}/setup?step=3")
      account_officer == 0 ->
        conn
        |> put_flash(:error, "At least one Account Officer is required")
        |> redirect(to: "/accounts/#{account.id}/setup?step=3")
      true ->
        step_financial(conn, account)
    end
  end

  defp contact_type(ag_id, type) do
    AccountContext.check_contact_type(ag_id, type)
  end

  def edit(conn, %{"id" => id, "step" => step}) do
    case AccountContext.get_account!(id) do
      %Account{} ->
        account = AccountContext.get_account!(id)
        validate_step(conn, account, step)
        start_date = compare_start_n_today_date(account.start_date)
        status = account.status

        if status == "Renewal Cancelled" ||
          status == "For Renewal" &&
            start_date == :gt do
              conn
              |> put_flash(:error, "This account is not editable")
              |> redirect(to: account_path(conn, :show, account.id, active: "profile"))
        else
          redirect_step(conn, step, account)
            end
      _ ->
        data_is_nil(conn, "Account not found!.")
    end
  end

  defp redirect_step(conn, step, account) do
    case step do
      "1" ->
        step_general(conn, account)
      "2" ->
        step_address(conn, account)
      "3" ->
        step_contact(conn, account)
      "4" ->
        step_financial(conn, account)
      "5" ->
        step_hoed(conn, account)
      "6" ->
        step_general(conn, account)
      _ ->
        conn
        |> put_flash(:error, "Invalid step!")
        |> redirect(to: account_path(conn, :index))
    end
  end

  defp compare_start_n_today_date(nil), do: nil
  defp compare_start_n_today_date(start_date) do
    start_date
    |> Ecto.Date.cast!()
    |> Ecto.Date.compare(Ecto.Date.utc)
  end

  defp validate_step(conn, account, step) do
    string_step = String.contains?(step, ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])

    if string_step == true do
      String.to_integer(step)
    else
      conn
      |> put_flash(:error, "Not allowed!")
      |> redirect(to: account_path(conn, :index))
    end
  end

  # def validate_step(conn, account, step) do
  #   if account.step < String.to_integer(step) do
  #     conn
  #     |> put_flash(:error, "Not allowed!")
  #     |> redirect(to: account_path(conn, :index))
  #   end
  # end

  def update_setup(conn, %{"id" => id, "step" => step,
    "account" => account_params})
  do
    case AccountContext.get_account!(id) do
      %Account{} ->
        account = AccountContext.get_account!(id)
        case step do
          "1" ->
            update_general(conn, account, account_params)
          "2" ->
            update_address(conn, account, account_params)
          "3" ->
            update_contact(conn, account, account_params)
          "4" ->
            update_financial(conn, account, account_params)
          _ ->
            conn
            |> put_flash(:error, "Invalid step!")
            |> redirect(to: account_path(conn, :index))
        end
      _ ->
        data_is_nil(conn, "Account not found!.")
    end
  end

  # Methods
  def index(conn, _) do
    render(conn, "index.html")
  end

  def index_versions(conn, %{"id" => account_group_id}) do
    case AccountContext.get_account_group(account_group_id) do
      %AccountGroup{} ->
    AccountContext.expired_account(account_group_id)
    AccountContext.reactivation_account(account_group_id)
    AccountContext.suspension_account(account_group_id)
    AccountContext.cancellation_account(account_group_id)
    AccountContext.active_account(account_group_id)
    accounts = AccountContext.list_versions(account_group_id)
    account_group = AccountContext.get_account_group(account_group_id)
    account_groups = ClusterContext.get_selected_account(account_group_id)
    changeset = AccountContext.change_account(%Account{})
    render(
      conn,
      "index_versions.html",
      changeset: changeset,
      accounts: accounts,
      account_group: account_group,
      account_groups: account_groups
    )
      _ ->
        data_is_nil(conn, "Account_Group not found!.")
    end
  end

  def new(conn, _params) do
    changeset = AccountContext.change_account_group(%AccountGroup{})
    render(
      conn,
      "new_general.html",
      changeset: changeset,
      industry: industry(),
      organization: organization()
    )
  end

  def create(conn, %{"account" => account_params}) do
    with {true, _id} <- UtilityContext.valid_uuid?(account_params["industry_id"]) do
      code = String.first(account_params["segment"])
      account_params =
        account_params
        |> Map.put("step", 2)
        |> Map.put("created_by", conn.assigns.current_user.id)
        |> Map.put("updated_by", conn.assigns.current_user.id)
        |> Map.put("code", AccountContext.account_code_checker(code))
        |> Map.put("start_date", to_valid_date(account_params["start_date"]))
        |> Map.put("end_date", to_valid_date(account_params["end_date"]))
        |> Map.put("original_effective_date", to_valid_date(account_params["start_date"]))

      case AccountContext.create_account_group(account_params) do
        {:ok, account_group} ->
          account_params =
            account_params
            |> Map.put("account_group_id", account_group.id)
            |> Map.put("major_version", 1)
            |> Map.put("minor_version", 0)
            |> Map.put("build_version", 0)
            |> Map.put("status", "Draft")

          {:ok, account} = AccountContext.create_account(account_params)
          AccountContext.update_photo(account_group, account_params)
          conn
          |> put_flash(:info, "General Info created successfully.")
          |> redirect(to: "/accounts/#{account.id}/setup?step=2")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(
            conn,
            "new_general.html",
            changeset: changeset,
            industry: industry(),
            organization: organization()
          )
      end
    else
      _ ->
        conn
        |> put_flash(:error, "Invalid Parameters!")
        |> redirect(to: "/accounts/new")
    end
  end

  def step_general(conn, account) do
    account_group =
      account.account_group_id
      |> AccountContext.get_account_group
      |> AccountContext.preload_account_group

    changeset = AccountContext.change_account_group(account_group)
    active_account = AccountContext.get_active_account(account.account_group_id)
    render(
      conn,
      "edit_general.html",
      account: account,
      account_group: account_group,
      changeset: changeset,
      industry: industry(),
      organization: organization(),
      active_account: active_account)
  end

  defp if_start_date_is_nil(account_params, nil) do
    account_params
    |> Map.put("end_date", to_valid_date(account_params["end_date"]))
  end

  defp if_start_date_is_nil(account_params, start_date) do
    account_params
    |> Map.put("start_date", to_valid_date(account_params["start_date"]))
    |> Map.put("end_date", to_valid_date(account_params["end_date"]))
  end

  def update_general(conn, account, account_params) do
    account_params = if_start_date_is_nil(account_params, account_params["start_date"])
    account_group = AccountContext.get_account_group(account.account_group_id)
    active_account = AccountContext.get_active_account(account.account_group_id)

    if account.status == "For Activation" do
      start =
        account_params["start_date"]
        |> Ecto.Date.cast!()
        |> Ecto.Date.compare(Ecto.Date.utc)

      beyond_expiry =
        account_params["start_date"]
        |> Ecto.Date.cast!()
        |> Ecto.Date.compare(Ecto.Date.cast!(account_params["end_date"]))

      cond do
        beyond_expiry == :gt ->
          message = "Effective Date must not go beyond the Expiry Date."
          conn
          |> put_flash(:error, message)
          |> redirect(to: account_path(conn, :edit, account.id, step: 1))
        start != :gt ->
          conn
          |> put_flash(:error, "Effective Date must be future dated.")
          |> redirect(to: account_path(conn, :edit, account.id, step: 1))
        true ->
          update_general(
            conn,
            account,
            account_group,
            account_params,
            active_account
          )
      end
    else
          update_general(
            conn,
            account,
            account_group,
            account_params,
            active_account
          )
    end
  end

  defp update_general(conn, account, account_group, account_params, active_account) do
    with {true, _id} <- UtilityContext.valid_uuid?(account_params["industry_id"]),
         {:ok, account_group} <- AccountContext.update_account_group(account_group, account_params),
         {:ok, account} <- update_account(account, account_group, account_params)
    do
      AccountContext.update_photo(account_group, account_params)
      AccountContext.forced_status(account, account_params)
      AccountContext.create_photo_log(
        conn.assigns.current_user,
        AccountGroup.changeset_photo(account_group, account_params),
        "General"
      )
      AccountContext.create_account_log(
        conn.assigns.current_user,
        AccountGroup.changeset(account_group, account_params),
        "General"
      )

      account = AccountContext.get_account!(account.id)
      increment_build_version(account)

      conn
      |> put_flash(:info, "General Info updated successfully.")
      |> redirect(to: account_step(conn, account, account.step, downcase(account.status)))
    else
      {:error, changeset} ->
        render(
          conn,
          "edit_general.html",
          account: account,
          account_group: account_group,
          changeset: changeset,
          industry: industry(),
          organization: organization(),
          active_account: active_account
        )
      _ ->
        conn
        |> put_flash(:error, "Error updating General Info.")
        |> redirect(to: account_step(conn, account, 0, downcase(account.status)))
    end
  end

  defp update_account(account, account_group, params) do
    account.id
    |> AccountContext.get_account_with_account_group(account_group.id)
    |> AccountContext.update_account(params)
  end

  defp account_step(conn, account, 7, "for activation"), do: "/accounts/#{account.id}?active=profile"
  defp account_step(conn, account, 7, _), do: account_path(conn, :edit, account, step: 1)
  defp account_step(conn, account, 0, _), do: account_path(conn, :setup, account, step: 1)
  defp account_step(conn, account, _, _), do: account_path(conn, :setup, account, step: 2)

  defp downcase(nil), do: ""
  defp downcase(string), do: String.downcase("#{string}")

  def step_address(conn, account) do
    account_group_id = account.account_group_id

    if account.step > 2 do
      account_address = get_address(account_group_id, "Account Address")
      billing_address = get_address(account_group_id, "Billing Address")
      billing = billing_values(billing_address)
      changeset = AccountGroupAddress.changeset(account_address)

      render(
        conn,
        "edit_address.html",
        account: account,
        changeset: changeset,
        billing: billing
      )
    else
      billing = empty_billing()
      changeset = AccountGroupAddress.changeset(%AccountGroupAddress{})

      render(
        conn,
        "new_address.html",
        account: account,
        changeset: changeset,
        billing: billing
      )
    end
  end

  defp billing_values(nil), do: empty_billing()
  defp billing_values(billing_address), do: billing_address

  def create_address(conn, %{"id" => account_id, "account" => account_params,
    "account_group" => account_group_id})
  do
    params = drop_v2_address(account_params)
    billing_params = drop_v1_address(account_params)
    company =
      params
      |> Map.put("account_group_id", account_group_id)
      |> Map.put("type", "Account Address")

    case AccountContext.create_address(company) do
      {:ok, _account} ->
        count_keys = Enum.count(account_params)
        create_billing(
          account_group_id,
          billing_params,
          count_keys
        )

        AccountContext.update_account_step(
          AccountContext.get_account!(account_id),
          %{step: 3, updated_by: conn.assigns.current_user.id}
        )

        conn
        |> put_flash(:info, "Address created successfully.")
        |> redirect(to: "/accounts/#{account_id}/setup?step=3")

      {:error, %Ecto.Changeset{} = changeset} ->
        account = AccountContext.get_account!(account_id)
        render(
          conn,
          "new_address.html",
          changeset: changeset,
          account: account,
          billing: empty_billing()
        )
    end
  end

  defp drop_v1_address(params) do
    Map.drop(params, [
      "account_id",
      "line_1",
      "line_2",
      "city",
      "province",
      "region",
      "country",
      "postal_code"
    ])
  end

  defp drop_v2_address(params) do
    Map.drop(params, [
      "account_id",
      "line_1_v2",
      "line_2_v2",
      "city_v2",
      "province_v2",
      "region_v2",
      "country_v2",
      "postal_code_v2"
    ])
  end

  defp create_billing(ag_id, billing_params, keys) when keys > 8 do
    insert_billing_address(ag_id, billing_params)
  end
  defp create_billing(ad_ig, billing_params, keys), do: nil

  defp insert_billing_address(account_group_id, billing_params) do
    billing_params
    |> Enum.into(%{}, fn {k, v} -> {String.trim(k, "_v2"), v} end)
    |> Map.put("account_group_id", account_group_id)
    |> Map.put("type", "Billing Address")
    |> Map.put("is_check", false)
    |> AccountContext.create_address
  end

  def update_address(conn, account, account_params) do
    company = drop_v2_address(account_params)
    account_group_id = account.account_group_id
    ag_address = get_address(account_group_id, "Account Address")
    count =
      account_group_id
      |> AccountContext.get_all_account_group_address()
      |> Enum.count

    case AccountContext.update_account_group_address(ag_address, company) do
      {:ok, _updated_account_address} ->

        update_billing(conn, account, account_params, count)

        AccountContext.create_account_group_log(
          conn.assigns.current_user,
          AccountGroupAddress.changeset(ag_address, account_params),
          "Address[Account]"
        )

        AccountContext.update_account_step(
          AccountContext.get_account!(account.id),
          %{updated_by: conn.assigns.current_user.id}
        )

        if account.step == 7 do
          account = AccountContext.get_account!(account.id)
          increment_build_version(account)

          conn
          |> put_flash(:info, "Address updated successfully.")
          |> redirect(to: "/accounts/#{account.id}/edit?step=2")
        else
          conn
          |> put_flash(:info, "Address updated successfully.")
          |> redirect(to: "/accounts/#{account.id}/setup?step=3")
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        render(
          conn,
          "edit_address.html",
          account: account,
          changeset: changeset,
          billing: empty_billing()
        )
    end
  end

  defp update_billing(conn, account, account_params, count) do
    billing = v2_address_params(account_params)
    count_account_keys = Enum.count(account_params)
    account_group_id = account.account_group_id
    params = %{
      account_params: account_params,
      ag_id: account_group_id,
      billing: billing
    }
    update_address(
      conn,
      params,
      count_account_keys,
      count
    )
  end

  defp v2_address_params(params) do
    params
    |>  Map.drop([
      "line_1",
      "line_2",
      "city",
      "province",
      "region",
      "country",
      "postal_code",
    ])
    |> Enum.into(%{}, fn {k, v} -> {String.trim(k, "_v2"), v} end)
    |> Map.put("is_check", false)
  end

  defp update_address(conn, params, count1, count2)
    when count1 > 8 and count2 == 2
  do
    account_group_address = get_address(params.ag_id, "Billing Address")
    AccountContext.update_account_group_address(account_group_address, params.billing)

    AccountContext.create_account_group_log(
      conn.assigns.current_user,
      AccountGroupAddress.changeset(account_group_address, params.account_params),
      "Address[Billing]"
    )
  end

  defp update_address(conn, params, count1, count2)
    when count1 > 8
  do
    _account_params = Map.delete(params.account_params, "is_check")
    insert_billing_address(params.ag_id, params.billing)
  end

  defp update_address(conn, params, count1, count2)
    when count2 == 2
  do
    account_group_address = get_address(params.ag_id, "Billing Address")
    AccountContext.delete_account_group_address(account_group_address)
  end

  defp update_address(conn, params, count1, count2), do: nil

  defp get_address(ag_id, type) do
    AccountContext.get_account_group_address!(ag_id, type)
  end

  def step_contact(conn, account) do
    changeset = Contact.changeset(%Contact{})
    contacts = AccountContext.get_all_contacts(account.account_group_id)
    render(
      conn,
      "new_contact.html",
      account: account,
      contacts: contacts,
      changeset: changeset
    )
  end

  def create_contact(conn, %{"id" => account_group_id,
    "account" => account_params})
  do
    account_params =
      account_params
      |> Map.put("ctc_date_issued", to_valid_date(account_params["ctc_date_issued"]))
      |> Map.put("passport_date_issued", to_valid_date(account_params["passport_date_issued"]))
    if is_nil(account_params["telephone"]) do
      Map.put(account_params, "telephone", [""])
    else
      account_params
    end

    account_id = account_params["account_id"]
    account = AccountContext.get_account!(account_id)

    case AccountContext.create_contact(account_params) do
      {:ok, contact} ->
        insert_contact(contact.id, account_params)

        AccountContext.create_account_contact(%{
          account_group_id: account_group_id,
          contact_id: contact.id
        })

       AccountContext.create_added_contact_log(
          account.account_group_id,
          conn.assigns.current_user,
          contact,
          "Contact"
       )

       conn
       |> put_flash(:info, "Contact created successfully.")
       |> redirect(to: "/accounts/#{account_id}/setup?step=3")

      {:error, %Ecto.Changeset{} = changeset} ->
        contacts = AccountContext.get_all_contacts(account_group_id)
        account = AccountContext.get_account!(account_id)

        render(
          conn,
          "new_contact.html",
          changeset: changeset,
          contacts: contacts,
          account: account
        )
    end
  end

  def update_contact(conn, account, account_params) do
    contact = ContactContext.get_contact!(account_params["contact_id"])
    account_params =
      account_params
      |> Map.put("ctc_date_issued", to_valid_date(account_params["ctc_date_issued"]))
      |> Map.put("passport_date_issued", to_valid_date(account_params["passport_date_issued"]))

    case AccountContext.update_account_contact(contact, account_params) do
      {:ok, updated_contact} ->

        AccountContext.delete_number(contact.id)
        insert_contact(contact.id, account_params)

        AccountContext.create_contact_log(
          account.account_group_id,
          conn.assigns.current_user,
          Contact.changeset(contact, account_params),
          "Contact")

        AccountContext.delete_contact(account.account_group_id, contact.id)
        AccountContext.create_account_contact(%{
          account_group_id: account.account_group_id,
          contact_id: updated_contact.id
        })

        conn
        |> put_flash(:info, "Contact updated successfully.")
        |> redirect(to: "/accounts/#{account.id}/setup?step=3")
      {:error, %Ecto.Changeset{} = changeset} ->
        contacts = AccountContext.get_all_contacts(account.id)
        account = AccountContext.get_account!(account.id)

        render(
          conn,
          "new_contact.html",
          changeset: changeset,
          contacts: contacts,
          account: account
        )
    end
  end

  defp insert_contact(contact_id, account_params) do
    Enum.each(["mobile", "telephone", "fax"], fn(param) ->
      country_code = ""
      area_code = ""
      local = ""
      case param do
        "mobile" ->
          country_code = account_params["mobile_country_code"]
        "telephone" ->
          country_code = account_params["tel_country_code"]
          area_code = account_params["tel_area_code"]
          local = account_params["tel_local"]
        "fax" ->
          country_code = account_params["fax_country_code"]
          area_code = account_params["fax_area_code"]
          local = account_params["fax_local"]
      end

      insert_number(%{
        contact_id: contact_id,
        number: account_params[param],
        type: param,
        country_code: country_code,
        area_code: area_code,
        local: local
      })
    end)
  end

  def next_contact(conn, %{"id" => account_id}) do
    account = AccountContext.get_account!(account_id)

    if account.step == 6 do
      conn
      |> redirect(to: "/accounts/#{account_id}/edit?step=4")
    else
      if account.step == 3 do
        AccountContext.update_account_step(
          AccountContext.get_account!(account.id),
          %{step: 5, updated_by: conn.assigns.current_user.id}
        )
      end
      conn
        |> redirect(to: "/accounts/#{account.id}/setup?step=5")
    end
  end

  def step_financial(conn, account) do
    account_group = AccountContext.get_account_group(account.account_group_id)
    approvers = AccountContext.list_all_approver(account_group.id)
    payment_account = AccountContext.get_account_payment!(account_group.id)
    bank = AccountContext.get_bank(account_group.id)
    coverage_funds = AccountContext.get_all_ag_coverage_fund(account_group.id)

    if account.step > 4 do
      bank =
        if is_nil(bank) do
          nil
        else
          bank
        end

      if is_nil(payment_account) do
        conn
        |> put_flash(:error, "Account has invalid financial setup!")
        |> redirect(to: "/accounts/#{account.id}/edit?step=1")
      else
        changeset = PaymentAccount.changeset(payment_account)
        render(
          conn,
          "edit_financial.html",
          account: account,
          approvers: approvers,
          changeset: changeset,
          bank: bank,
          account_group: account_group,
          coverage_funds: coverage_funds,
          coverages: coverages
        )
      end

    else

      if payment_account do
        bank = bank
        changeset = PaymentAccount.changeset(payment_account)
      else
        bank = nil
        changeset = PaymentAccount.changeset(%PaymentAccount{})
      end

      render(
        conn,
        "new_financial.html",
        account: account,
        changeset: changeset,
        account_group: account_group,
        approvers: approvers,
        bank: bank,
        coverage_funds: coverage_funds,
        coverages: coverages
      )
    end
  end

  def create_financial(conn, %{"id" => account_group_id,
    "account" => account_params})
  do
    account_group_params =
      take_approval_params(account_params, account_group_id)
    account_params = Map.merge(account_params, account_group_params)
    account = AccountContext.get_account_group!(account_group_id)

    case AccountContext.create_payment(account_params) do
      {:ok, _payment} ->
        create_bank(
          account_params,
          account_group_id,
          account_params["mode_of_payment"]
        )

        update_account_group_financial(account_group_id, account_group_params)

        AccountContext.update_account_step(
          AccountContext.get_account!(account.id),
          %{step: 5, updated_by: conn.assigns.current_user.id}
        )

        conn
        |> put_flash(:info, "Financial created successfully.")
        |> redirect(to: "/accounts/#{account.id}/setup?step=5")

      {:error, %Ecto.Changeset{} = changeset} ->
        account_group = AccountContext.get_account_group(account_group_id)
        approvers = AccountContext.list_all_approver(account_group_id)
        account = AccountContext.get_account!(account.id)
        coverage_funds = AccountContext.get_all_ag_coverage_fund(account_group_id)

        render(
          conn,
          "new_financial.html",
          account: account,
          account_group: account_group,
          approvers: approvers,
          changeset: changeset,
          bank: nil,
          coverage_funds: coverage_funds,
          coverages: coverages
        )
    end
  end

  defp take_approval_params(account_params, account_group_id) do
    account_params
    |> Map.take([
      "approval_mode_of_payment",
      "approval_account_no",
      "approval_account_name",
      "approval_branch",
      "approval_authority_debit",
      "approval_payee_name",
      "approval_is_check"
    ])
    |> Enum.into(%{}, fn {k, v} -> {String.slice(k, 9..50), v} end)
    |> Map.put("account_group_id", account_group_id)
  end

  defp create_bank(account_params, account_group_id, mode)
    when  mode == "Electronic Debit"
  do
    account_params
    |> Map.take(["account_name", "account_no", "branch"])
    |> Map.merge(%{"account_group_id" => account_group_id})
    |> AccountContext.create_bank_account()
  end
  defp create_bank(account_params, account_group_id, mode), do: nil

  def update_financial(conn, account, account_params) do
    payment = AccountContext.get_account_payment!(account.account_group_id)
    account_group = AccountContext.get_account_group(account.account_group_id)
    coverage_funds = AccountContext.get_all_ag_coverage_fund(account_group.id)
    account_params = account_params(account_params, account)
    approval_params = account_approval_params(account_params)
    account_group_params =
      account_group_params(account_params, approval_params, account)

    case AccountContext.update_account_payment(payment, account_params) do
      {:ok, _updated_payment} ->
        update_bank_with_logs(
          conn,
          account_params,
          account_group.id,
          account_params["mode_of_payment"]
        )

        ag_financial_params =
          financial_params(account_group_params,
                           account_params["mode_of_payment"])

        update_account_group_financial(account_group.id, ag_financial_params)

        # LOGS
        AccountContext.create_account_log(
          conn.assigns.current_user,
          AccountGroup.changeset_financial(account_group, account_group_params),
          "Financial [Approval]"
        )

        # LOGS
        AccountContext.create_payment_log(
          conn.assigns.current_user,
          PaymentAccount.changeset_account(payment, account_params),
          "Financial"
        )

        financial_redirect_step(
          conn,
          account,
          account.step
        )
      {:error, %Ecto.Changeset{} = changeset} ->
        account = AccountContext.get_account!(account.id)
        account_group = AccountContext.get_account_group(account_group.id)
        approvers = AccountContext.list_all_approver(account_group.id)
        bank = AccountContext.get_bank(account.id)

        render(
          conn,
          "edit_financial.html",
          account: account,
          changeset: changeset,
          bank: bank,
          account_group: account_group,
          approvers: approvers,
          coverage_funds: coverage_funds,
          coverages: coverages
        )
    end
  end

  defp financial_redirect_step(conn, account, step) when step == 7 do
    account = AccountContext.get_account!(account.id)
    increment_build_version(account)
    conn
    |> put_flash(:info, "Financial updated successfully.")
    |> redirect(to: "/accounts/#{account.id}/edit?step=4")
  end

  defp financial_redirect_step(conn, account, step) do
    AccountContext.update_account_step(account, %{"step" => "5"})
    conn
    |> put_flash(:info, "Financial updated successfully.")
    |> redirect(to: "/accounts/#{account.id}/setup?step=5")
  end

  defp account_params(account_params, account) do
    account_params
    |> Map.put("payee_name", nil)
    |> Map.put("account_group_id", account.account_group_id)
    |> Map.put("payee_name", account_params["payee_name"])
  end

  defp account_approval_params(account_params) do
    %{
      "mode_of_payment" => account_params["approval_mode_of_payment"],
      "account_no" => account_params["approval_account_no"],
      "account_name" => account_params["approval_account_name"],
      "branch" => account_params["approval_branch"],
      "authority_debit" => account_params["approval_authority_debit"],
      "payee_name" => account_params["approval_payee_name"],
      "is_check" => account_params["approval_is_check"]
     }
  end

  defp account_group_params(account_params, approval_params, account) do
    account_params
    |> Map.take([
      "approval_mode_of_payment",
      "approval_account_no",
      "approval_account_name",
      "approval_branch",
      "approval_authority_debit",
      "approval_payee_name",
      "approval_is_check"
    ])
    |> Enum.into(%{}, fn {key, value} -> {String.slice(key, 9..50), value} end)
    |> Map.put("account_group_id", account.account_group_id)
    |> Map.merge(approval_params)
  end

  defp update_account_group_financial(account_group_id, ag_financial_params) do
    account_group_id
    |> AccountContext.get_account_group()
    |> AccountContext.update_account_group_financial(ag_financial_params)
  end

  defp update_bank_with_logs(conn, account_params, account_group_id, mode)
    when mode === "Electronic Debit"
  do
    bank_params =
      account_params
      |> Map.take(["account_name", "account_no", "branch"])

      account_group_id
      |> AccountContext.get_bank()
      |> AccountContext.update_bank_account(bank_params, account_group_id)

      banked = AccountContext.get_bank(account_group_id)
      AccountContext.create_bank_log(
        conn.assigns.current_user,
        Bank.changeset(banked, account_params),
        "Financial"
       )
  end

  defp update_bank_with_logs(conn, account_params, account_group_id, mode) do
    AccountContext.delete_bank(account_group_id)
  end

  defp financial_params(ag_params, mode_of_payment)
    when mode_of_payment === "Electronic Debit"
  do
    ag_params
    |> Map.put("payee_name", nil)
  end

  defp financial_params(ag_params, mode_of_payment) do
    ag_params
    |> Map.put("account_no", nil)
    |> Map.put("account_name", nil)
    |> Map.put("branch", nil)
  end

  defp remove_brackets(string) do
    string
    |> String.slice(7..50)
    |> String.trim("[")
    |> String.trim("]")
  end

  def on_click_update(conn, %{"id" => account_group_id, "params" => params}) do
    account_params =
      params
      |> Enum.into(%{}, fn{key, value} ->
          {remove_brackets(key), value}
         end)

    approval_params = %{
      "mode_of_payment" => params["account[approval_mode_of_payment]"],
      "account_no" => params["account[approval_account_no]"],
      "account_name" => params["account[approval_account_name]"],
      "branch" => params["account[approval_branch]"],
      "authority_debit" => params["account[approval_authority_debit]"],
      "payee_name" => params["account[approval_payee_name]"]
    }

    account_group_params =
      account_params
      |> Map.take([
          "approval_mode_of_payment",
          "approval_account_no",
          "approval_account_name",
          "approval_branch",
          "approval_authority_debit",
          "approval_payee_name"
        ])
      |> Enum.into(%{}, fn {k, v} -> {String.slice(k, 9..50), v} end)
      |> Map.put("account_group_id", account_group_id)
      |> Map.merge(approval_params)

    payment = AccountContext.get_account_payment!(account_group_id)
    account_params =
      account_params
      |> Map.put("account_group_id", account_group_id)

    account_payment =
      if payment do
        AccountContext.update_account_payment_v2(payment, account_params)
      else
        AccountContext.create_payment_v2(account_params)
        AccountContext.update_account_step(
          AccountContext.get_account!(params["account[account_id_v2]"]),
          %{step: 5, updated_by: conn.assigns.current_user.id}
        )
      end

    case account_payment do
      {:ok, _payment} ->
        account_group_id
        |> AccountContext.get_account_group
        |> AccountContext.update_account_group_financial(account_group_params)

        if account_params["mode_of_payment"] === "Electronic Debit" do
          bank =
            account_params
            |> Map.take(["account_name", "account_no", "branch"])

            account_group_id
            |> AccountContext.get_bank()
            |> AccountContext.update_bank_account(bank, account_group_id)
        else
          AccountContext.delete_bank(account_group_id)
        end

        json conn, Poison.encode!("true")
      {:error, %Ecto.Changeset{} = _changeset} ->
        json conn, Poison.encode!("false")
    end
  end

  def create_approver(conn, %{"id" => account_group_id,
    "account" => approval_params})
  do
    approval_params =
      approval_params
      |> Enum.into(%{}, fn {k, v} -> {String.slice(k, 9..20), v} end)
      |> Map.put("account_group_id", account_group_id)
      |> Map.put("account_id", approval_params["account_id"])

    account = AccountContext.get_account!(approval_params["account_id"])

    case AccountContext.create_account_approver(approval_params) do
      {:ok, approver} ->
        AccountContext.create_added_approver_log(
          account.account_group_id,
          conn.assigns.current_user,
          approver)

        if account.step == 7 do
          conn
          |> redirect(to: "/accounts/#{account.id}/edit?step=4")
        else
          conn
          |> redirect(to: "/accounts/#{account.id}/setup?step=4")
        end
      {:error, %Ecto.Changeset{} = changeset} ->
        account = AccountContext.get_account!(account.id)
        account_group_id = account.account_group_id
        account_group = AccountContext.get_account_group(account_group_id)
        approvers = AccountContext.list_all_approver(account_group_id)
        bank = AccountContext.get_bank(account.id)
        coverage_funds = AccountContext.get_all_ag_coverage_fund(account_group.id)

        render(
          conn,
          "edit_financial.html",
          account: account,
          changeset: changeset,
          bank: bank,
          account_group: account_group,
          approvers: approvers,
          coverage_funds: coverage_funds,
          coverages: coverages
        )
    end
  end

  def delete_approver(conn, %{"id" => account_group_approval_id,
    "account_id" => account_id})
  do
    account = AccountContext.get_account!(account_id)
    approver = AccountContext.get_approver!(account_group_approval_id)
    AccountContext.delete_approver!(approver)
    AccountContext.create_deleted_approver_log(
      account.account_group_id,
      conn.assigns.current_user,
      approver
    )

    if account.step == 6 do
      conn
      |> put_flash(:info, "Approver deleted successfully.")
      |> redirect(to: "/accounts/#{account_id}/edit?step=4")
    else
      conn
      |> put_flash(:info, "Approver deleted successfully.")
      |> redirect(to: "/accounts/#{account_id}/setup?step=4")
    end
  end

  def step_summary(conn, account) do
    account_group = AccountContext.get_summary_account(account)
    render(
      conn,
      "new_summary.html",
      account_group: account_group,
      account: account
    )
  end

  def submit_summary(conn, %{"id" => account_id}) do
    account = AccountContext.get_account!(account_id)

    status =
      account.start_date
      |> Ecto.Date.cast!()
      |> Ecto.Date.compare(Ecto.Date.utc)

    if status == :gt do
      if account.step == 6 do
        AccountContext.update_account_step(
          AccountContext.get_account!(account_id),
          %{
            step: 7,
            status: "Pending",
            updated_by: conn.assigns.current_user.id
           }
        )
      end

      conn
      |> put_flash(:info, "Account successfully created.")
      |> redirect(to: account_path(conn, :show, account.id, active: "profile"))
    else
      conn
      |> put_flash(:info, "Account Effectivity Date must be future dated.")
      |> redirect(to: "/accounts/#{account_id}/setup?step=5")
    end
  end

  def create_product(conn, %{"id" => account_id,
    "account_product" => account_product_params})
  do
    product = String.split(account_product_params["product_ids"], ",")

    peme =
    Enum.map(product, fn(x) ->
      if x == "" do
        nil
      else
        product = ProductContext.get_product(x)
        if product.product_category == "PEME Plan" do
          product.product_category
        else
          nil
        end
      end
    end)

    peme =
    peme
    |> Enum.reject(fn(x) -> is_nil(x) end)

    account = AccountContext.get_account!(account_id)
    status? =
      account.status == "Active" ||
      account.status == "Lapsed" ||
      account.status == "Pending" ||
      account.status == "For Activation"

    cond do
      status? == false ->
        conn
        |> put_flash(
          :error,
          "Account status should be active or lapsed to add plan."
        )
        |> redirect(to: account_path(conn, :show, account_id,
                                     active: "product"))
      product == [""] ->
        conn
        |> put_flash(:error, "Please select atleast one plan")
        |> redirect(to: account_path(conn, :show, account_id,
                                     active: "product"))
     # Enum.count(peme) > 1 ->
     #    conn
     #    |> put_flash(:error, "Product cannot be added. Only one PEME Product is allowed to be added in an account")
     #    |> redirect(to: account_path(conn, :show, account_id,
     #                                 active: "product"))
      true ->
        # AccountContext.delete_all_account_product(
        #   account_id,
        #   account_product_params["standard"]
        # )

        keys = [
          :name,
          :description,
          :type,
          :limit_applicability,
          :limit_type,
          :limit_amount,
          :standard_product
        ]
        Enum.each(product, fn(product_id) ->
          last_key = AccountContext.check_last_ap_rank(account_id)
          product_id
          |> AccountContext.get_product()
          |> Map.take(keys)
          |> Map.merge(%{account_id: account_id,
            product_id: product_id, rank: last_key}
          )
          |> AccountContext.create_account_product
        end)

        increment_minor_version(account)

        conn
        |> put_flash(:info, "Account Plan successfully added.")
        |> redirect(to: account_path(conn, :show, account_id,
                                     active: "product"))
    end
  end

  def update_product(conn, %{"id" => account_id,
    "account_product" => account_product_params})
  do
    account_product_id = account_product_params["account_product_id"]
    account = AccountContext.get_account!(account_id)
    product = AccountContext.get_account_product!(account_product_id)

    case AccountContext.update_account_product(product, account_product_params)
    do
      {:ok, _product} ->
        increment_minor_version(account)
        conn
        |> redirect(to: account_path(conn, :show, account.id,
                                     active: "product"))
      {:error, %Ecto.Changeset{} = changeset} ->
        account_products = AccountContext.list_all_account_products(account.id)
        account = AccountContext.get_account!(account.id)
        products = AccountContext.list_all_products()
        account_group =
          AccountContext.get_account_group(account.account_group_id)
        render(
          conn,
          "tab_product.html",
          account: account,
          products: products,
          changeset_account_product: changeset,
          account_products: account_products,
          account_group: account_group,
          active: "product")
    end
  end

  def delete_account_product(conn, params) do
    account_product = AccountContext.get_account_product!(params["ap_remove"]["account_product_id"])

    if is_nil(account_product) do
      conn
      |> put_flash(
        :error,
        "Error in Deleting Account Product!"
      )
      |> redirect(to: account_path(conn, :show, params["ap_remove"]["account_id"], active: "product"))
    else
      account = AccountContext.get_account!(account_product.account_id)
      delete_account_product(conn, params, account_product, account)
    end
  end

  defp delete_account_product(conn, params, account_product, account) do
    ap_params = params["ap_remove"]
    account_id = ap_params["account_id"]
    ranking_list_params = ap_params["product_tier_ranking"]
    account_product_id = ap_params["account_product_id"]

    status? =
      account.status == "Active" ||
      account.status == "Lapsed" ||
      account.status == "Pending" ||
      account.status == "For Activation"

    if status? do
      increment_minor_version(account)
      AccountContext.delete_account_product!(account_product)

      ranking_list =
        ranking_list_params
        |> String.split(",")

      if Enum.count(ranking_list) > 1 do
         product_ranking_list(ranking_list, account_product_id, account_id)
      end

      conn
      |> put_flash(:info, "Account Plan successfully deleted.")
      |> redirect(to: account_path(conn, :show, account.id, active: "product"))
    else
      conn
      |> put_flash(
        :error,
        "Account status should be active or lapsed to remove plan."
      )
      |> redirect(to: account_path(conn, :show, account.id, active: "product"))
    end
  end

  defp product_ranking_list(ranking_list, account_product_id, account_id) do
    list_with_nil = [] ++ for rank <- ranking_list do
      ap_list =
        rank
        |> String.split("_")

      if Enum.at(ap_list, 1) == account_product_id do
        [Enum.at(ap_list, 0), nil]
      else
        ap_list
      end
    end

    nil_val_list = [] ++ for rank <- list_with_nil do
      if Enum.at(rank, 1) == nil do
        rank
      end
    end

    nil_val =
      nil_val_list
      |> Enum.uniq
      |> List.delete(nil)
      |> List.flatten
      |> Enum.at(0)
      |> String.to_integer

    updated_rank = [] ++ for rank <-  list_with_nil do
      if String.to_integer(Enum.at(rank, 0)) > nil_val do
        prev_val = String.to_integer(Enum.at(rank, 0)) - 1
        [Integer.to_string(prev_val), Enum.at(rank, 1)]
      else
        if Enum.at(rank, 1) != nil do
          rank
        else
          nil
        end
      end
    end

    updated_rank =
      updated_rank
      |> Enum.uniq
      |> List.delete(nil)

    updated_ranking_list = [] ++ for rank <- updated_rank do
      Enum.join(rank, "_")
    end

    updated_ranking_list =
      updated_ranking_list
      |> Enum.join(",")

    update_product_tier(updated_ranking_list, account_id)
  end

  def delete_account_contact(conn, %{"id" => contact_id,
    "account_id" => account_id})
  do
    account = AccountContext.get_account!(account_id)
    account_group_id = account.account_group_id
    contact = AccountContext.get_contact!(contact_id)

    if account.step == 7 do
      corp_signatory = contact_type(account_group_id, "Corp Signatory")
      contact_person = contact_type(account_group_id, "Contact Person")
      account_officer = contact_type(account_group_id, "Account Officer")

      cond do
        contact.type == "Corp Signatory" && corp_signatory == 1 ->
          conn
          |> put_flash(:error, "At least one Corp Signatory is required")
          |> redirect(to: "/accounts/#{account.id}/edit?step=3")
        contact.type == "Contact Person" && contact_person == 1 ->
          conn
          |> put_flash(:error, "At least one Contact Person is required")
          |> redirect(to: "/accounts/#{account.id}/edit?step=3")
        contact.type == "Account Officer" && account_officer == 1 ->
          conn
          |> put_flash(:error, "At least one Account Officer is required")
          |> redirect(to: "/accounts/#{account.id}/edit?step=3")
        true ->
          delete_contact(contact_id, account.account_group_id)
          AccountContext.create_deleted_contact_log(
            account.account_group_id,
            conn.assigns.current_user,
            contact
            )
          conn
          |> put_flash(:info, "Contact deleted successfully.")
          |> redirect(to: "/accounts/#{account.id}/edit?step=3")
      end

    else
      delete_contact(contact_id, account.account_group_id)
        AccountContext.create_deleted_contact_log(
          account.account_group_id,
          conn.assigns.current_user,
          contact)
      conn
      |> put_flash(:info, "Contact deleted successfully.")
      |> redirect(to: "/accounts/#{account.id}/setup?step=3")
    end
  end

  defp delete_contact(contact_id, account_group_id) do
    AccountContext.delete_number(contact_id)
    AccountContext.delete_contact(account_group_id, contact_id)
  end

  def delete(conn, %{"id" => account_group_id}) do
   if AccountContext.delete_account(account_group_id) do
     conn
     |> put_flash(:info, "Account deleted successfully.")
     |> redirect(to: account_path(conn, :index))
   else
     conn
     |> put_flash(:error, "This Account is cannot be deleted.")
     |> redirect(to: account_path(conn, :index))
   end
  end

  def show(conn, %{"id" => id, "active" => active}) do
    pem = conn.private.guardian_default_claims["pem"]["accounts"]
    case AccountContext.get_account!(id) do
      %Account{} ->
        account = AccountContext.get_account!(id)
        changeset_account_product = AccountProduct.changeset(%AccountProduct{})
        account_products = AccountContext.list_all_account_products(account.id)
        products = [] #AccountContext.list_all_products()
        account_comment = AccountContext.get_all_comments(account.id)
        changeset_account = AccountContext.change_account(%Account{})
        changeset_account_comment =
          AccountContext.change_account_comment(%AccountComment{})
        account_group = AccountContext.get_summary_account(account)
        account_groups = AccountContext.get_account_group(account.account_group_id)
        account_group_address =
          AccountContext.get_account_group_address!(
          account.account_group_id, "Company Address")
        latest_version = AccountContext.get_latest_account(account.account_group_id)
        for_renewal_version =
            AccountContext.get_for_renewal_account_version(account.account_group_id)
        render(
          conn,
          "show.html",
          active: active,
          account: account,
          account_group: account_group,
          account_groups: account_groups,
          account_group_address: account_group_address,
          account_products: account_products,
          account_comment: account_comment,
          products: products,
          changeset_account: changeset_account,
          changeset_account_product: changeset_account_product,
          changeset_account_comment: changeset_account_comment,
          latest_version: latest_version,
          for_renewal_version: for_renewal_version,
          permission: pem
        )
    _ ->
      data_is_nil(conn, "Account not found!.")
    end
  end

  def show(conn, %{"id" => id}) do
    show(conn, %{"id" => id, "active" => "profile"})
  end

  def edit(conn, %{"id" => id}) do
    case AccountContext.get_account!(id) do
      %Account{} ->
        account = AccountContext.get_account!(id)
        account_group = AccountContext.get_account_group(account.account_group_id)
        changeset = AccountContext.change_account(account)
        active_account = AccountContext.get_active_account(account.account_group_id)
        render(
          conn,
          "edit_general.html",
          account_group: account_group,
          account: account,
          changeset: changeset,
          industry: industry(),
          organization: organization(),
          active_account: active_account)
      _ ->
        data_is_nil(conn, "Account not found!.")
    end
  end

  def update_cancel(conn, %{"id" => id, "cancel_account" => account_params}) do
    _account = AccountContext.get_account!(id)
    _account_group =
      AccountContext.get_account_group!(account_params["account_id"])
    account = AccountContext.get_account!(account_params["account_id"])
    case AccountContext.update_account_cancel(account, account_params) do
      {:ok, account} ->
        _account_group =
          AccountContext.get_account_group(account_params["account_group_id"])
        params = %{
          cancellation_date: account_params["cancel_date"],
          cancellation_reason: account_params["cancel_reason"],
          cancellation_remarks: account_params["cancel_remarks"]
        }

        AccountContext.create_cancel_logs(
              account_params["account_group_id"],
              conn.assigns.current_user,
              params
        )
        conn
        |> put_flash(:info,
                     "Account will be canceled on #{account.cancel_date}."
        )
        |> redirect(
            to: "/accounts/#{account_params["account_id"]}?active=profile"
        )
    end
  end

  def update_cancel(conn,account_params) do
    conn
    |> put_flash(:error, "Error in cancelling account.")
    |> redirect(
      to: "/accounts/#{account_params["account_id"]}?active=profile"
    )
  end

  def extend_account(conn, %{"account" => account_params}) do
    account = AccountContext.get_account!(account_params["account_id"])
    if account.status == "Active" do
      case AccountContext.update_account_expiry(account, account_params) do
        {:ok, _account} ->
          _account_group =
            AccountContext.get_account_group(account_params["account_group_id"])
          params = %{
            new_expiry_date: account_params["end_date"]
          }

          AccountContext.create_extend_logs(
            account_params["account_group_id"],
            conn.assigns.current_user,
            params
          )
          conn
          |> put_flash(:info, "Account successfully Extended!")
          |> redirect(
            to: "/accounts/#{account_params["account_id"]}?active=profile"
          )
        {:error, _error} ->
          conn
          |> put_flash(:error, "New Expiry Date is required.")
          |> redirect(
            to: "/accounts/#{account_params["account_id"]}?active=profile"
          )
      end
      else
      conn
      |> put_flash(:error, "Status is not Active!")
      |> redirect(
        to: "/accounts/#{account_params["account_id"]}?active=profile"
      )
    end
  end

  def suspend_account_in_account(conn, %{"account" => account_params}) do
    account = AccountContext.get_account!(account_params["account_id"])
    case AccountContext.suspend_account(account, account_params) do
      {:ok, _account} ->
        _account_group =
          AccountContext.get_account_group(account_params["account_group_id"])
        params = %{
          suspension_reason: account_params["suspend_reason"],
          suspension_date: account_params["suspend_date"],
          suspension_remarks: account_params["suspend_remarks"]

        }

        AccountContext.create_suspend_logs(
              account_params["account_group_id"],
              conn.assigns.current_user,
              params
          )
        conn
        |> put_flash(:info, "Successfully suspend an account.")
        |> redirect(
          to: "/accounts/#{account_params["account_id"]}?active=profile"
        )
      {:error, _error} ->
        conn
        |> put_flash(:error, "Failed to suspend an account.")
        |> redirect(
          to: "/accounts/#{account_params["account_id"]}?active=profile"
        )
    end
  end

  def create_account_comment(conn, %{"id" => _account_id,
    "account_comment" => account_params})
  do
    case AccountContext.create_comment(account_params) do
      {:ok, _result} ->
        json conn, Poison.encode!(account_params)
      {:error, _error} ->
        conn
        |> put_flash(:error, "Comment is required.")
    end
  end

  def renew_account(conn, %{"id" => account_id}) do
    account = AccountContext.get_account!(account_id)
    if account.status == "Active" || account.status == "Lapsed" do
      latest = AccountContext.get_latest_account(account.account_group_id)
      user = conn.assigns.current_user.id
      account_params =
        account
        |> Map.take([:step, :account_group_id])
        |> Map.put(:status, "For Activation")
        |> Map.put(:created_by, user)
        |> Map.put(:updated_by, user)
        |> Map.put(:major_version, latest.major_version + 1)
        |> Map.put(:minor_version, 0)
        |> Map.put(:build_version, 0)

      case AccountContext.create_renew(account_params) do
        {:ok, new_account} ->
          account_group =
            AccountContext.get_account_group(account_params.account_group_id)
          params = %{
            account_code: account_group.code,
            account_name: account_group.name
          }

          AccountContext.create_renew_logs(
                account_params.account_group_id,
                conn.assigns.current_user,
                params
          )

          AccountContext.clone_account_product(account, new_account)
          conn
          |> put_flash(:info, "Account new version successfully created.")
          |> redirect(to: account_path(conn, :edit, new_account.id, step: 1))
        {:error, _error} ->
          conn
          |> put_flash(:error, "Failed to renew due to incomplete data.")
          |> redirect(
            to: account_path(conn, :show, account.id, active: "profile")
          )
      end
    else
        conn
        |> put_flash(
          :error,
          "The status of account should be active or lapsed to renew."
        )
        |> redirect(
          to: account_path(conn, :show, account.id, active: "profile")
        )
    end
  end

  def activate_account(conn, %{"id" => account_id,
    "account" => account_params})
  do
    account = AccountContext.get_account!(account_id)
    cond do
      is_nil(account.start_date) || is_nil(account.end_date) ->
        conn
        |> put_flash(
          :error,
          "Make sure this account effectivity and expiry date are set"
        )
        |> redirect(to: account_path(conn, :edit, account.id, step: 1))

      account.status == "For Activation" ->
        case AccountContext.activate_status(account, account_params) do
          {:ok, account} ->
            account_version = Enum.join([
                    account.major_version,
                    account.minor_version,
                    account.build_version], ".")
            account_group_id = account.account_group_id
            account_group = AccountContext.get_account_group(account_group_id)
            account_code = account_group.code
            account_name = account_group.name
            params = %{
              account_code: account_code,
              account_name: account_name,
              account_version: account_version
            }
            AccountContext.create_activation_logs(
              account_group_id,
              conn.assigns.current_user,
              params
            )
            AccountContext.update_all_active(account)
            conn
            |> put_flash(:info, "Renewal successfully activated.")
            |> redirect(
              to: account_path(conn, :index_versions, account.account_group_id)
            )
          {:error, _error} ->
            conn
            |> put_flash(:error, "Account status is required.")
            |> redirect(
              to: account_path(conn, :show, account.id, active: "profile")
            )
        end

      true ->
        conn
        |> put_flash(
          :error,
          "Failed to activate due to status is not for activation."
        )
        |> redirect(
          to: account_path(conn, :show, account.id, active: "profile")
        )
    end
  end

  def cancel_renewal(conn, %{"id" => account_id,
    "account" => account_params})
  do
    account = AccountContext.get_account!(account_id)
    if account.status == "For Activation" do
      case AccountContext.renewal_cancel(account, account_params) do
        {:ok, account} ->
          account_version = Enum.join([
                  account.major_version,
                  account.minor_version,
                  account.build_version], ".")
          account_group_id = account.account_group_id
          account_group = AccountContext.get_account_group(account_group_id)
          account_code = account_group.code
          account_name = account_group.name
          params = %{
            account_code: account_code,
            account_name: account_name,
            account_version: account_version
          }
          AccountContext.create_cancelled_renewal_logs(
            account_group_id,
            conn.assigns.current_user,
            params
          )
          conn
          |> put_flash(:info, "Account status is now renewal cancelled.")
          |> redirect(
            to: account_path(conn, :index_versions, account.account_group_id)
          )
        {:error, _error} ->
          conn
          |> put_flash(:error, "Account status is required.")
          |> redirect(
            to: account_path(conn, :show, account.id, active: "profile")
          )
      end
    else
      conn
      |> put_flash(
        :error,
        "Failed to activate due to status is not for activation."
      )
      |> redirect(
        to: account_path(conn, :show, account.id, active: "profile")
      )
    end
  end

  def print_account(conn, %{"id" => account_id}) do
    case AccountContext.get_account!(account_id) do
      %Account{} ->
        account = AccountContext.get_account!(account_id)
        account_group = AccountContext.get_summary_account(account)

        html =
          View.render_to_string(
            AccountView,
            "print_summary.html",
            account_group: account_group,
            account: account,
            conn: conn)

            {date, time} = :erlang.localtime
            unique_id = Enum.join(Tuple.to_list(date)) <> Enum.join(Tuple.to_list(time))
            filename = "#{account_group.code}_#{unique_id}"

            with {:ok, content} <- PdfGenerator.generate_binary html,
                 filename: filename, delete_temporary: true
            do
              conn
              |> put_resp_content_type("application/pdf")
              |> put_resp_header("content-disposition",
                                 "inline; filename=#{filename}.pdf"
              )
              |> send_resp(200, content)
              # else
              #   {:error, reason} ->
              #     conn
              #     |> put_flash(:error, "Failed to print account.")
              #     |> redirect(to: "/accounts/#{account_id}?active=profile")
            end
      _ ->
        data_is_nil(conn, "Account not found!.")
    end
  end

  def reactivate_account_in_account(conn, %{"account" => account_params}) do
    account = AccountContext.get_account!(account_params["account_id"])
    case AccountContext.reactivate_account(account, account_params) do
      {:ok, _account} ->
        if account_params["module"] == "Account" do
          account_group =
            AccountContext.get_account_group(
              account_params["account_group_id"]
            )
          params = %{
            account_code: account_group.code,
            account_name: account_group.name,
            reactivate_date: account_params["reactivate_date"],
            reactivate_remarks: account_params["reactivate_remarks"]
          }

          AccountContext.create_reactivate_logs(
            account_params["account_group_id"],
            conn.assigns.current_user,
            params
          )

          conn
          |> put_flash(:info, "Successfully reactivate an account.")
          |> redirect(
            to: "/accounts/#{account_params["account_id"]}?active=profile"
          )
        else
          conn
          |> put_flash(:info, "Successfully reactivate an account.")
          |> redirect(to: "/clusters/#{account_params["cluster_id"]}/accounts/#{account_params["account_id"]}")
        end
      {:error, _error} ->
        if account_params["module"] == "Account" do
          conn
          |> put_flash(:error, "Failed to reactivate an account.")
          |> redirect(
            to: "/accounts/#{account_params["account_id"]}?active=profile"
          )
        else
          conn
          |> put_flash(:error, "Failed to reactivate an account.")
          |> redirect(to: "/clusters/#{account_params["cluster_id"]}/accounts/#{account_params["account_id"]}")
        end
    end
  end

  def download_accounts(conn, params) do
    account_details = AccountContext.download_accounts(params)
    json conn, Poison.encode!(account_details)
  end

  def retract_account(conn, %{"id" => account_id,
    "account" => account_params})
  do
    movement = account_params["movement"]
    with {:ok, account} <-
      AccountContext.retract_movement(movement, account_id)
    do
      account_group_id = account.account_group_id
      cond do
        movement == "Cancellation" ->
          params = %{
            account_movement: movement
          }
          AccountContext.create_retract_logs(
            account_group_id,
            conn.assigns.current_user,
            params
          )
        movement == "Reactivation" ->
          params = %{
            account_movement: movement
          }
          AccountContext.create_retract_logs(
            account_group_id,
            conn.assigns.current_user,
            params
          )
        movement == "Suspension" ->
          params = %{
            account_movement: movement
          }
          AccountContext.create_retract_logs(
            account_group_id,
            conn.assigns.current_user,
            params
          )
      end

      conn
      |> put_flash(:info, "Account movement is retracted.")
      |> redirect(to: "/accounts/#{account_id}?active=profile")
    else
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Error retracting movement")
        |> redirect(to: "/accounts/#{account_id}?active=profile")
    end
  end

  # Private Methods
  defp increment_minor_version(account) do
    AccountContext.update_account_version(
      account, %{"minor_version" => account.minor_version + 1}
    )
  end

  defp increment_build_version(account) do
    AccountContext.update_account_version(
      account, %{"build_version" => account.build_version + 1}
    )
  end

  defp industry do
    _industry =
      AccountContext.list_industry
      |> Enum.map(&{&1.code, &1.id})
  end

  defp organization do
    _organization =
      AccountContext.list_organization
      |> Enum.map(&{&1.name, &1.id})
  end

  defp coverages do
    CoverageContext.get_all_coverages
    |> Enum.map(&{&1.name, &1.id})
  end

  defp empty_billing do
    keys =
      [
        :line_1,
        :line_2,
        :street,
        :city,
        :province,
        :region,
        :country,
        :postal_code
      ]
   Map.new(keys, fn(key) -> {key, ""} end)
  end

  defp insert_number(params) do
    Enum.each(Enum.with_index(params.number, 0), fn({number, counter}) ->
      local =
      if params.type == "mobile" do
          nil
      else
        if is_nil(params.local) || params.local == "" do
          nil
        else
          Enum.at(params.local, counter)
        end
      end
      area_code =
      if params.type == "mobile" do
          nil
      else
        if is_nil(params.area_code) || params.area_code == "" do
          nil
        else
          Enum.at(params.area_code, counter)
        end
      end
      country_code =
      if is_nil(params.country_code) do
        "+63"
      else
        Enum.at(params.country_code, counter)
      end
      AccountContext.create_contact_no(%{
        contact_id: params.contact_id,
        number: String.replace(number, "-", ""),
        local: local,
        area_code: area_code,
        country_code: country_code,
        type: params.type
      })
    end)
  end

  # API
  def remove_photo(conn, %{"id" => account_group_id, "account_id" => account_id}) do
    account_group = AccountContext.get_account_group(account_group_id)
    if not is_nil(account_group.photo) do
       AccountContext.create_delete_photo_log(
          conn.assigns.current_user,
          account_group.id,
          account_group.photo.file_name
      )
    end
    AccountContext.update_photo(account_group, %{"photo" => nil})

    conn
    |> put_flash(:info, "Photo successfully removed.")
    |> redirect(to: "/accounts/#{account_id}/setup?step=1")
  end

  def get_contact(conn, %{"id" => contact_id}) do
    contact = ContactContext.get_contact!(contact_id)
    json conn, Poison.encode!(contact)
  end

  def get_all_account_name(conn, _params) do
    account =  AccountContext.get_all_account_name()
    json conn, Poison.encode!(account)
  end

  def get_all_account_tin(conn, _params) do
    account_tin =  AccountContext.get_all_account_tin()
    json conn, Poison.encode!(account_tin)
  end

  def get_all_group_accounts(conn, %{"account_id" => account_id}) do
    account = ClusterContext.get_all_group_accounts(account_id)
    json conn, Poison.encode!(account)
  end

  def get_an_account(conn, %{"id" => account_id}) do
    account = AccountContext.get_account!(account_id)
    json conn, Poison.encode!(account)
  end

  def get_account_product(conn, %{"id" => account_product_id}) do
    account_product = AccountContext.get_account_product!(account_product_id)
    json conn, Poison.encode!(account_product)
  end

  # Product Tier
  def save_product_tier(conn, params) do
    product_tier_params =  params["product_tier"]
    ranking_list_params = product_tier_params["product_tier_ranking"]
    account_id = product_tier_params["account_id"]
    if is_nil(ranking_list_params) do
      conn
      |> put_flash(:error, "Plan Tier not found.")
      |> redirect(to: "/accounts")
    else
      result = update_product_tier(ranking_list_params, account_id)

      if Enum.member?(result, "error") do
        conn
        |> put_flash(:error, "Plan Tier was not updated.")
        |> redirect(to: "/accounts/#{account_id}/?active=product")
      else
        conn
        |> put_flash(:info, "Plan Tier was successfully updated.")
        |> redirect(to: "/accounts/#{account_id}/?active=product")
      end
    end

  end

  defp update_product_tier(ranking_list_params, _account_id) do
    ranking_list =
      ranking_list_params
      |> String.split(",")

    for product_rank <- ranking_list do
      product_info =
        product_rank
        |> String.split("_")

      rank = Enum.at(product_info, 0)
      account_product_id = Enum.at(product_info, 1)
      case AccountContext.update_product_tier(account_product_id, rank) do
        {:ok, _account_product} ->
          "ok"
        {:error, _changeset} ->
          "error"
        _ ->
          "error"
      end
    end
  end

  def step_hoed(conn, account) do
    account_group =
      account.account_group_id
      |> AccountContext.get_account_group
      |> AccountContext.preload_account_group

    if account.step > 5 do
      render(conn, "edit_hoed.html", account: account,
             account_group: account_group)
    else
      render(conn, "new_hoed.html", account: account,
             account_group: account_group)
    end
  end

  def save_ahoed(conn, %{"account_id" => account_id,
    "account_params" => account_params}) do
    married_employee = account_params["me_sortable"]
    single_employee = account_params["se_sortable"]
    single_parent_employee = account_params["spe_sortable"]

    if married_employee == "" or single_employee == ""
    or single_parent_employee == "" do
      json conn, Poison.encode!("fail")
    else
      AccountContext.clear_account_hierarchy(account_id)

      account = AccountContext.get_account!(account_id)

      insert_hoed(account.account_group_id,
                  married_employee, "Married Employee"
      )
      insert_hoed(account.account_group_id,
                  single_employee, "Single Employee"
      )
      insert_hoed(account.account_group_id,
                  single_parent_employee, "Single Parent Employee"
      )
      AccountContext.insert_enrollment_period(account.account_group_id,
                                              account_params)
      if AccountContext.get_account!(account_id).step < 7 do
        AccountContext.update_account_step(account_id, 6)
      end

      json conn, Poison.encode!("success")
    end
  end

  defp insert_hoed(account_group_id, dependent_string_array, hierarchy_type) do
    dependent_array = String.split(dependent_string_array, ",")

    for dependent <- dependent_array do
      dependent_record = String.split(dependent, "-")
      dependent = Enum.at(dependent_record, 1)
      ranking = Enum.at(dependent_record, 0)

      AccountContext.insert_account_hierarchy(account_group_id, hierarchy_type,
                                              dependent, ranking)
    end
  end

  def create_coverage_fund(conn, params) do
    account_group_id = params["id"]
    params = params["params"]
    params = %{
      account_group_id: account_group_id,
      coverage_id: params["coverage_ids"],
      revolving_fund: String.replace(params["account[revolving_fund]"], ",", ""),
      replenish_threshold: String.replace(params["account[replenish_threshold]"], ",", "")
    }
    with :ok <- AccountContext.insert_coverage_fund(params) do
        coverage_funds = AccountContext.get_all_ag_coverage_fund(account_group_id)
        json conn, Poison.encode!(coverage_funds)
    else
      _ ->
        json conn, Poison.encode!(false)
    end
  end

  def delete_coverage_fund(conn, %{"id" => coverage_fund_id}) do
    with coverage_fund = %AccountGroupCoverageFund{} <- AccountContext.get_coverage_fund(coverage_fund_id),
         {:ok, agcf} <- AccountContext.delete_coverage_fund(coverage_fund)
    do
      coverage_funds = AccountContext.get_all_ag_coverage_fund(coverage_fund.account_group_id)
      json conn, Poison.encode!(coverage_funds)
    else
      _ ->
        json conn, Poison.encode!(false)
    end
  end

  def data_is_nil(conn, message) do
    conn
    |> put_flash(:error, message)
    |> redirect(to: account_path(conn, :index))
  end

  def load_products_tbl(conn, params) do
    added_products = ProductContext.get_added_products(params["id"])
    coverage_available = ProductContext.get_funding_arrangement_coverage(params["id"])
    count = ProductContext.get_products_tbl_count(params["type"], added_products, coverage_available)
    products =
      ProductContext.get_products_tbl(
        params["type"],
        added_products,
        coverage_available,
        params
      )
    conn
    |> json(%{
      data: products,
      draw: params["draw"],
      recordsTotal: count,
      recordsFiltered: count
    })
  end

  def account_index(conn, params) do
    count = AccountDatatable.get_accounts_count(params["search"]["value"], params["id"])
    accounts = AccountDatatable.get_accounts(params["start"], params["length"], params["search"]["value"], params["id"])
    conn |> json(%{data: accounts, draw: params["draw"], recordsTotal: count, recordsFiltered: count})
  end

  def to_valid_date(date) do
    UtilityContext.transform_string_dates(date)
  end
end
