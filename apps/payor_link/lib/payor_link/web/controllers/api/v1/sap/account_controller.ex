defmodule Innerpeace.PayorLink.Web.Api.V1.Sap.AccountController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Base.{
    MigrationContext,
    Api.Sap.AccountContext
  }

  alias Innerpeace.Db.Base.Api.AccountContext, as: AccountContextApi

  alias PayorLink.Guardian, as: PG
  alias Innerpeace.PayorLink.Web.Api.V1.Migration.MigrationView
  alias Innerpeace.PayorLink.Web.Endpoint
  alias Innerpeace.PayorLink.Web.Api.V1.AccountView
  alias Innerpeace.Db.Schemas.Account

  def create(conn, %{"params" => params}) do
    if is_nil(PG.current_resource_api(conn)) do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")
    else
      user = PG.current_resource_api(conn)
      case AccountContext.validate_insert(%{id: user.id}, params) do
        {:ok, account_group_v2, account_product, approver} ->
          account_group_v2 = Map.merge(account_group_v2, %{account_products: account_product, approvers: approver})
          render(conn, AccountView, "show_new.json", account_group_v2: account_group_v2)
        {:error, changeset} ->
          conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "changeset_error.json", message: changeset, code: 400)
        {:not_found} ->
          conn
          |> put_status(:not_found)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
      end
    end
  end

  def create(conn, params) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Parameters")
  end

  def create_v2(conn, params) do
    if is_nil(PG.current_resource_api(conn)) do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")
    else
      user = PG.current_resource_api(conn)
      case AccountContext.create(user.id, params) do
        {:ok, account_group} ->
          render(conn, AccountView, "create_sap.json", account_group: account_group)

        {:error, changeset} ->
          conn
          |> put_status(400)
          |> render(Innerpeace.PayorLink.Web.Api.V1.ErrorView, "changeset_error.json", message: changeset, code: 400)
        {:not_found} ->
          conn
          |> put_status(:not_found)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
      end
    end
  end

  def renew_account(conn, params) do

    with true <- params["version"] != "",
         true <- not is_nil(params["version"]) do

      with true <- params["code"] != "",
           true <- not is_nil(params["code"]) do


        effectivity_date_format(conn, params["effectivity_date"])
        expiry_date_format(conn, params["expiry_date"])
        with true <- not is_nil(major_version = AccountContextApi.get_major_version(params["version"])),
             not is_nil(minor_version = AccountContextApi.get_minor_version(params["version"])),
             not is_nil(build_version = AccountContextApi.get_build_version(params["version"]))
        do
          if is_nil(PG.current_resource_api(conn)) do
            conn
            |> put_status(:not_found)
            |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")
          else
            code = params["code"]
            single_account = AccountContextApi.renew_account_join(code, major_version, minor_version, build_version)

            with true <- not is_nil(single_account) do

              account = AccountContextApi.get_account_V2!(single_account)
              validate_account(conn, params, account, account.status)
            else
              false ->
                conn
                |> put_status(400)
                |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Account not existing")

            end
          end
        end
      else
        false ->
        conn

        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please enter Account code.")

        _ ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please complete the details.")


      end
      else
      false ->
      conn
      |> put_status(400)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please enter Account version.")

      _ ->
      conn
      |> put_status(400)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please complete the details.")

           end
         end

  defp validate_account(conn, params, account, "Active") do

    latest = AccountContextApi.get_latest_account(account.account_group_id)
    latest_active = AccountContextApi.get_latest_active_account(account.account_group_id)
    start_date = Ecto.Date.cast!(params["effectivity_date"])
    end_date = Ecto.Date.cast!(params["expiry_date"])
    user = PG.current_resource_api(conn)
    with true <- not is_nil(latest_for_renewal = AccountContextApi.get_latest_for_renewal_account(account.account_group_id)) do
         conn
      |> put_status(400)
      |> json(
        %{ result: "The version that you're trying to renew has For Renewal version" })
    else
      false ->

    if latest_active.id != account.id do
      conn
      |> put_status(400)
      |> json(
        %{ result: "The version that you're trying to renew is not the latest version" })
    else

      with {:ok, test} <- AccountContextApi.validate_renew_account_fields(account, latest, params),
           {:ok, test} <- AccountContextApi.check_cancellation_date(params, latest_active),
           {:valid, test} <- AccountContextApi.validate_renew_account_expiry_date(params)  do
        account_params =
          account
          |> Map.take([:step, :account_group_id])
          |> Map.put(:status, "For Activation")
          |> Map.put(:created_by, user.id)
          |> Map.put(:updated_by, user.id)
          |> Map.put(:major_version, latest.major_version + 1)
          |> Map.put(:minor_version, 0)
          |> Map.put(:build_version, 1)
          |> Map.put(:start_date, start_date)
          |> Map.put(:end_date, end_date)

        case AccountContextApi.create_renew(account_params) do
          {:ok, new_account} ->

            account_group =
              AccountContextApi.get_account_group(account_params.account_group_id)
            params = %{
              account_code: account_group.code,
              account_name: account_group.name
            }

            AccountContextApi.clone_account_product_v2(account, new_account)
            conn
            |> put_status(200)
            render(conn, Innerpeace.PayorLink.Web.Api.V1.AccountView, "account_renew.json", new_account: new_account)

          {:error, _error} ->
            conn
            |> put_status(400)
            |> json(
              %{ result: "Failed to renew" })
        end
        else
        {:start_date_error, date} ->
        conn
        |> put_status(400)
        |> json(
          %{ result: "Effectivity Date must be greater than #{account.end_date}" })


        {:end_date_error, date} ->
        conn
        |> put_status(400)
        |> json(
          %{ result: "Expiry Date must be greater than #{params["effectivity_date"]}" })

        {:cancellation_date_error, date} ->
        conn
        |> put_status(400)
        |> json(
          %{ result: "The account you're trying to renew has a future movement" })

           end
    end
    end

  end


  defp validate_account(conn, params, account, "Lapsed") do
    latest = AccountContextApi.get_latest_account(account.account_group_id)
    latest_active = AccountContextApi.get_latest_active_account(account.account_group_id)
    start_date = Ecto.Date.cast!(params["effectivity_date"])
    end_date = Ecto.Date.cast!(params["expiry_date"])
    with true <- not is_nil(latest_for_renewal = AccountContextApi.get_latest_for_renewal_account(account.account_group_id)) do
         conn
      |> put_status(400)
      |> json(
        %{ result: "The version that you're trying to renew has For Renewal version" })
    else
      false ->

    if latest_active.id != account.id do
       conn
      |> put_status(400)
      |> json(
        %{ result: "The version that you're trying to renew is not the latest version" })


    else
      with {:valid, test} <- AccountContextApi.validate_renew_account_expiry_date(params),
           {:ok, test} <- AccountContextApi.check_cancellation_date(params, latest_active)

      do

      case Ecto.Date.compare(start_date, Ecto.Date.cast!(Date.utc_today())) do
        :gt ->

          user = PG.current_resource_api(conn)

          account_params =
            account
            |> Map.take([:step, :account_group_id])
            |> Map.put(:status, "For Activation")
            |> Map.put(:created_by, user.id)
            |> Map.put(:updated_by, user.id)
            |> Map.put(:major_version, latest.major_version + 1)
            |> Map.put(:minor_version, 0)
            |> Map.put(:build_version, 1)
            |> Map.put(:start_date, start_date)
            |> Map.put(:end_date, end_date)


          case AccountContextApi.create_renew(account_params) do
            {:ok, new_account} ->

              account_group =
                AccountContextApi.get_account_group(account_params.account_group_id)
              params = %{
                account_code: account_group.code,
                account_name: account_group.name
              }


              AccountContextApi.clone_account_product_v2(account, new_account)
              conn
              |> put_status(200)
              render(conn, Innerpeace.PayorLink.Web.Api.V1.AccountView, "account_renew.json", new_account: new_account)

            {:error, _error} ->
              conn
              |> put_status(400)
              |> json(
                %{ result: "Failed to renew" })

          end

          :lt ->
          conn
          |> put_status(400)
          |> json(
            %{ result: "Effectivity date must be greater than current date" })

          :eq ->
          conn
          |> put_status(400)
          |> json(
            %{ result: "Effectivity date must be greater than current date" })

          _ ->
          conn
          |> put_status(400)
          |> json(
            %{ result: "Failed to renew" })
      end

      else
      {:end_date_error, date} ->
      conn
      |> put_status(400)
      |> json(
        %{ result: "Expiry Date must be greater than #{params["effectivity_date"]}" })

      {:cancellation_date_error, date} ->
      conn
      |> put_status(400)
      |> json(
        %{ result: "The account you're trying to renew has a future movement" })


      end
    end
  end
  end

  defp validate_account(conn, params, account, _) do
    conn
    |> put_status(400)
    |> json(
      %{ result: "Account is not active or not lapsed" })
  end

  defp effectivity_date_format(conn, effectivity_date) do
    with true <- AccountContextApi.is_date?(effectivity_date) do

    else
      false ->
      conn
      |> put_status(400)
      |> json(
      %{ result: "Invalid date format in effectivity date" })

  end
  end

  defp expiry_date_format(conn, expiry_date) do
    with true <- AccountContextApi.is_date?(expiry_date) do

    else
      false ->
        conn
        |> put_status(400)
        |> json(
          %{ result: "Invalid date format in expiry date" })

    end
  end

  def cancel_account(conn, params) when is_map(params) do
    if is_nil(PG.current_resource_api(conn)) do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView,
                "error.json",
                message: "Please login again to refresh token.")
    else
      user = PG.current_resource_api(conn)

      params =
        params
        |> Map.put("created_by", user.id)
        |> Map.put("updated_by", user.id)
        :cancel_account
        |> AccountContext.valid_params?(params)
        |> return_result("account_cancel.json", conn)

    end
  end

  defp return_result({:ok, account}, json_name, conn) do
    conn
    |> put_status(200)
    |> render(Innerpeace.PayorLink.Web.Api.V1.AccountView, json_name, account: account)
  end

  defp return_result({:error, changeset}, _, conn) do
    conn
    |> put_status(400)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
  end

  def reactivate_account(conn, params) do
    if is_nil(PG.current_resource_api(conn)) do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView,
                "error.json",
                message: "Please login again to refresh token.")
    else
      user = PG.current_resource_api(conn)

      params =
        params
        |> Map.put("created_by", user.id)
        |> Map.put("updated_by", user.id)

        :reactivate_account
        |> AccountContext.valid_params?(params)
        |> return_result("account_reactivate.json", conn)
    end
  end

  def suspend_account(conn, params) when is_map(params) do
    if is_nil(PG.current_resource_api(conn)) do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")
    else
      user = PG.current_resource_api(conn)
      params =
        params
        |> Map.put("created_by", user.id)
        |> Map.put("updated_by", user.id)

      :suspend_account
      |> AccountContext.valid_params?(params)
      |> return_result("account_suspend.json", conn)
    end
  end

  def extend_account(conn, params) when is_map(params) do
    if is_nil(PG.current_resource_api(conn)) do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")
    else
      user = PG.current_resource_api(conn)
      params =
        params
        |> Map.put("created_by", user.id)
        |> Map.put("updated_by", user.id)

      :extend_account
      |> AccountContext.valid_params?(params)
      |> return_result("account_extend.json", conn)
    end
  end

  def get_account(conn, %{"code" => code, "name" => name}) do
    account_group = AccountContext.get_sap_account(code, name)
    case account_group do
      {:multiple_results} ->
        conn
        |> put_status(400)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Error, query returned multiple results")
      {:no_record_found} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Account not found")
      {:ok, account}->
        render(conn, AccountView, "get_sap.json", account_group: account)
      _ ->
         raise "haha"
    end
  end

  def get_account(conn, params) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Code and Name is required")
  end

end

