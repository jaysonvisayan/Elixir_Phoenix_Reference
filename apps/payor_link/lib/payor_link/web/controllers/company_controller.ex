defmodule Innerpeace.PayorLink.Web.CompanyController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Base.CompanyContext
  alias Innerpeace.Db.Schemas.{
    Company
  }

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{companies: [:manage_company]},
       %{companies: [:access_company]},
     ]] when action in [
       :index,
       :show
     ]

  plug Guardian.Permissions.Bitwise,
    [handler: Innerpeace.PayorLink.Web.FallbackController,
     one_of: [
       %{companies: [:manage_company]},
     ]] when not action in [
       :index,
       :show
     ]

  plug :valid_uuid?, %{origin: "companies"}
  when not action in [:index]

  def index(conn, _params) do
    companies = CompanyContext.list_all_companies()
    render(conn, "index.html", companies: companies)
  end

  def new(conn, _params) do
    changeset = CompanyContext.change_companies(%Company{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"company" => company_params}) do
    duplicate = CompanyContext.get_company_by_code(company_params["code"])
    duplicate =
      duplicate
      |> Enum.uniq()
      |> List.first()
    if is_nil(duplicate) do
      with {:ok, _company} <- CompanyContext.create_company(company_params) do
        companies = CompanyContext.list_all_companies()
        render(conn, "index.html", companies: companies, modal_open: true)

      else
        {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
      end
    else
      changeset = CompanyContext.company_changeset(company_params)
      conn
      |> put_flash(:error, "Company Code already exists.")
      |> render("new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    companies = CompanyContext.get_company(id)
    render(conn, "show.html", companies: companies)
  end
  
  def get_company_by_code(conn, %{"code" => code}) do
    company = CompanyContext.get_company_by_code(code)
    json conn, Poison.encode!(company)
  end

end
