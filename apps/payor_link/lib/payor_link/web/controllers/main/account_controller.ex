defmodule Innerpeace.PayorLink.Web.Main.AccountController do
  use Innerpeace.PayorLink.Web, :controller
  alias Phoenix.View
  alias Innerpeace.PayorLink.Web.Main.AccountView
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

  def index(conn, %{}) do
    render(conn, "index.html")
  end

  # Vue Js
  def view(conn, %{"code" => code}) do
    render(conn, "view.html", code: code)
  end

end
