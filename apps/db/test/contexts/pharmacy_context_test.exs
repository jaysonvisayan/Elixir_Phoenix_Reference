defmodule Innerpeace.Db.Base.PharmacyContextTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.{
    Pharmacy
  }
  alias Innerpeace.Db.Base.PharmacyContext

  test "get_all_pharmacyi/0, returns all pharmacy records" do
    pharmacy_records = insert(:pharmacy)
    assert PharmacyContext.get_all_pharmacy() == [pharmacy_records]
  end

  test "create_pharmacy/1, inserts  pharmacy record with valid parameters" do
     user = insert(:user)
     params = %{
       "created_by_id" => user.id,
       "updated_by_id" => user.id,
       "drug_code" => "0001",
       "generic_name" => "Ibuprofen",
       "brand" => "Medicol",
       "strength" => "500",
       "form" => "Capsule",
       "maximum_price" => "10.5"
     }
    {:ok, pharmacy_rec} = PharmacyContext.create_pharmacy(params)
    assert pharmacy_rec.form == "Capsule"
    assert pharmacy_rec.brand == "Medicol"
    assert pharmacy_rec.generic_name == "Ibuprofen"
  end

  test "create_pharmacy/1, inserts  pharmacy record with invalid parameters" do
    params = %{
      "drug_code" => "0001",
       "generic_name" => "",
       "brand" => "Medicol"
     }
    {:error, changeset} = PharmacyContext.create_pharmacy(params)
     assert changeset.valid? == false
  end

  test "update_pharmacy/2, update a pharmacy record with valid parameters" do
    user = insert(:user)
    pharmacy_rec = insert(:pharmacy)
    params = %{
       "created_by_id" => user.id,
       "updated_by_id" => user.id,
       "drug_code" => "0001",
       "generic_name" => "Ibuprofen",
       "brand" => "Medicol",
       "strength" => "500",
       "form" => "Capsule",
       "maximum_price" => "10.5"
    }
    assert  {:ok, pharmacy} = PharmacyContext.update_pharmacy(pharmacy_rec.id, params)
    assert pharmacy.drug_code == "0001"
    assert pharmacy.generic_name == "Ibuprofen"
  end

  test "update_pharmacy/2, update a pharmacy record with invalid parameters" do
    pharmacy_rec = insert(:pharmacy)
    params = %{
       "drug_code" => "0001",
       "generic_name" => "",
       "brand" => "Medicol"
          }

    {:error, changeset} = PharmacyContext.update_pharmacy(pharmacy_rec.id, params)
    assert changeset.valid? == false
  end

  test "delete_pharmacy/1, deletes a pharmacy record" do
    pharmacy = insert(:pharmacy)
    params = %{"id" => pharmacy.id}
    PharmacyContext.delete_pharmacy(params["id"])

    phar =
      Pharmacy
      |> Repo.get_by(id: pharmacy.id)

    assert is_nil(phar)
  end
end
