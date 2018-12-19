defmodule Innerpeace.PayorLink.Web.Api.V1.AccountController do
  use Innerpeace.PayorLink.Web, :controller
  alias Innerpeace.Db.Base.Api.{
    AccountContext
  }
  alias PayorLink.Guardian, as: GP

  def create_account_api(conn, %{"params" => params}) do
    if is_nil(GP.current_resource(conn)) do
      conn
      |> put_status(:not_found)
      |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Please login again to refresh token.")
    else

      case AccountContext.validate_insert(GP.current_resource(conn), params) do
        {:ok, account_group, account_product, approver} ->
          account_group = Map.merge(account_group, %{account_products: account_product, approvers: approver})
          render(conn, "show.json", account_group: account_group)
        {:error, changeset} ->
          conn
          |> put_status(:not_found)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
        {:not_found} ->
          conn
          |> put_status(:not_found)
          |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
      end

    end

  end

  def create_account_api(conn, params) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Parameters")
  end

  def create_account_api_existing(conn, %{"params" => params}) do
    case AccountContext.validate_insert_existing(GP.current_resource(conn), params) do
      {:ok, account_group, account_product, approver} ->
        account_group = Map.merge(account_group, %{account_products: account_product, approvers: approver})
        render(conn, "show.json", account_group: account_group)
      {:error, changeset} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
      {:not_found} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
    end
  end

  def get_an_account_by_code(conn, %{"code" => code}) do
    account_group = AccountContext.get_account_group_by_code(code)
    render_account_by_code(conn, account_group)
  end

  defp render_account_by_code(conn, ag) when not is_nil(ag) do
    render(conn, "account_group_2.json", account_group: ag)
  end

  defp render_account_by_code(conn, ag) when is_nil(ag) do
    conn
    |> put_status(:not_found)
    |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Not Found")
  end


  def index(conn, params) do
    has_account = Map.has_key?(params, "account")
    if Enum.count(params) >= 1 do
      cond do
        has_account == false ->
          conn
          |> put_status(404)
          |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Invalid parameters!")
        has_account == true and is_nil(params["account"]) ->
          conn
          |> put_status(404)
          |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Please input account name or code.")
        true ->
          params =
            params
            |> Map.put_new("account", "")
          account_group = AccountContext.search_accounts(params)
          render(conn, "index.json", account_group: account_group)
      end
    else
      account_group = AccountContext.get_all_accounts()
      render(conn, "index.json", account_group: account_group)
    end
  end

  def renew_account(conn, %{"params" => params}) do
    case AccountContext.validate_renew_account(GP.current_resource(conn), params) do
      {:ok, account} ->
        render(conn, "account.json", account: account)
      {:error, changeset} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
      {:not_authorized} ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: "Unauthorized")
    end
  end

  def get_account_latest(conn, _params) do
    account_group = AccountContext.get_account_latest()
    render(conn, "account_latest.json", account_group: account_group)
  end

  def set_account_replicated(conn, %{"params" => params}) do
    code = params["code"]
    case AccountContext.set_account_replicated(code) do
      {:ok, account_group} ->
        render(conn, "account_group_2.json", account_group: account_group)
      {:error, message} ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.Api.ErrorView, "error.json", message: message)
    end
  end

 def add_product(conn, params) do
    with true <- Map.has_key?(params, "_json") do
      accounts = Enum.map(params["_json"], &(AccountContext.validate_insert_product(&1)))
      if Enum.empty?(Enum.filter(accounts, &(Map.has_key?(&1, :errors)))) do
        Enum.map(params["_json"], &(AccountContext.insert_account_product(&1)))
      end
      conn
       |> render(Innerpeace.PayorLink.Web.Api.V1.AccountView, "batch.json", accounts: accounts)
    else
      {:error, changeset} ->
        conn
        |> put_status(:not_found)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "changeset_error.json", changeset: changeset)
      _ ->
        conn
        |> put_status(404)
        |> render(Innerpeace.PayorLink.Web.ErrorView, "error.json", message: "Invalid Parameters!", code: 404)
    end
  end

end
