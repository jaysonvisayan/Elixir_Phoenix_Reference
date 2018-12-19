defmodule Innerpeace.Db.Base.PharmacyContext do
  @moduledoc false

  import Ecto.{
    Query,
    Changeset
  }, warn: false

  alias Innerpeace.Db.{
    Repo,
    Schemas.Pharmacy
  }
  def get_all_pharmacy do
    Pharmacy
    |> Repo.all
  end

  def create_pharmacy(pharmacy_param) do
   %Pharmacy{}
   |> Pharmacy.changeset(pharmacy_param)
   |> Repo.insert()
  end

  def get_all_pharmacy_code do
    Pharmacy
    |> select([:drug_code])
    |> Repo.all
  end

  def get_pharmacy(id) do
    Pharmacy
    |> Repo.get(id)
  end

  def update_pharmacy(id, pharmacy_param) do
    id
    |> get_pharmacy()
    |> Pharmacy.changeset(pharmacy_param)
    |> Repo.update
  end

  def delete_pharmacy(id) do
    record =
      id
      |> get_pharmacy
      |> Repo.delete
  end
end
