defmodule AccountLinkWeb.AccountController do
  use AccountLinkWeb, :controller

  alias AccountLink.Guardian.Plug
  alias AccountLink.Guardian, as: AG
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Base.{
    AccountContext,
    ProductContext
  }
  alias Innerpeace.Db.Base.Api.AccountContext, as: ApiAccount

  def show_profile(conn, _params) do
    user = AG.current_resource(conn)
    user = Repo.preload(user, :user_account)
    id = user.user_account.account_group_id
    with account_group <- AccountContext.get_account_group(id) do
      account = for account <- account_group.account do
        if account.status == "Active" do
          account
        end
      end
      account =
        account
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.first()
      contacts = AccountContext.get_all_contacts(account_group.id)
         render conn, "profile.html", account_group: account_group,
        account: account, contacts: contacts
    else
     {:error, message} ->
       conn
       |> put_flash(:error, message)
       |> redirect(to: "/accounts")
    end
  end

  def show_product(conn, _params) do
    user = AG.current_resource(conn)
    user = Repo.preload(user, :user_account)
    id = user.user_account.account_group_id
    account_group = AccountContext.get_account_group(id)
    account = List.first(account_group.account)
    account_products = AccountContext.list_all_account_products(account.id)
    render conn, "product.html", account_group: account_group,
     account: account, account_products: account_products
  end

  def show_product_summary(conn, %{"id" => id}) do
    product = ProductContext.get_product!(id)
    render conn, "product_summary.html", product: product
  end

  def show_finance(conn, _params) do
    user = AG.current_resource(conn)
    user = Repo.preload(user, :user_account)
    id = user.user_account.account_group_id
    account_group = AccountContext.get_account_group(id)
    account = List.first(account_group.account)

    render conn, "finance.html", account_group: account_group, account: account
  end

  def get_account(conn, %{"code" => code}) do
    account_group = ApiAccount.get_account_group_by_code(code)
    render(conn, "account_group_2.json", account_group: account_group)
  end

end
