defmodule Innerpeace.Db.Base.CompanyContext do
  import Ecto.{Query, Changeset}, warn: false

  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.Company
  }

  def list_all_companies do
    Company
    |> Repo.all
  end

  def create_company(attrs \\ %{}) do
    %Company{}
    |> Company.changeset(attrs)
    |> Repo.insert()
  end

  def company_changeset(attrs \\ %{}) do
    %Company{}
    |> Company.changeset(attrs)
  end

  def change_companies(%Company{} = company) do
    Company.changeset(company, %{})
  end

  def get_company(company_id) do
    Company
    |> Repo.get(company_id)
  end
  
  def get_company_by_code(code) do
    Company
    |> where([c], c.code == ^code)
    |> select([c], %{code: c.code, name: c.name, id: c.id})
    |> Repo.all()
  end
end