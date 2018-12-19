defmodule Innerpeace.PayorLink.Web.Api.AccountController do
  use Innerpeace.PayorLink.Web, :controller
  alias Innerpeace.Db.Base.{
    AccountContext,
  }

  def get_an_account(conn, %{"id" => account_id}) do
    account = AccountContext.get_account!(account_id)
    json conn, Poison.encode!(account)
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

end
