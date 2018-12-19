defmodule Innerpeace.PayorLink.Web.PharmacyControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase
  # import Innerpeace.PayorLink.TestHelper

  setup do
    conn = build_conn()
    user = fixture(:user_permission, %{keyword: "manage_pharmacies", module: "Pharmacies"})
    conn = authenticated(conn, user)
    pharmacy = insert(:pharmacy,
                      drug_code: "0001",
                      brand: "Medicol",
                      generic_name: "Ibuporfen",
                      created_by_id: user.id,
                     updated_by_id: user.id,
                     maximum_price: "10.5",
                     form: "Capsule",
                     strength: "500"
    )
    # conn = sign_in(conn, user)
    {:ok, %{conn: conn, pharmacy: pharmacy}}
  end

  test "index/2, lists all entries on index", %{conn: conn, pharmacy: pharmacy} do
     conn = get conn, pharmacy_path(conn, :index)
     assert html_response(conn, 200) =~ pharmacy.drug_code
  end

  test "new/2, remders form for creating new record", %{conn: conn} do
     conn = get conn, pharmacy_path(conn, :new)
    assert html_response(conn, 200) =~ "Add Medicine"
  end

  test "create/2, creates apharmacy record with valid attributes", %{conn: conn} do
     params = %{
       "drug_code" => "0002",
       "brand" => "Medicol",
       "generic_name" => "Ibuprofen",
       "strength" => "1,000",
       "form" => "Capsule",
       "maximum_price" => "100"
     }

    conn = post conn, pharmacy_path(conn, :new), pharmacy: params
    assert redirected_to(conn) == "/pharmacies"
  end

  test "create/2, creates apharmacy record with invalid attributes", %{conn: conn} do
     params = %{
       "drug_code" => "0001",
       "brand" => "Medicol",
       "generic_name" => "Ibuprofen",
       "strength" => "1,000",
       "form" => "",
       "maximum_price" => "100"
     }

    conn = post conn, pharmacy_path(conn, :new), pharmacy: params
    assert html_response(conn, 200) =~ "Error was encountered while saving"
  end

  test "edit/2, renders form for editing pharmacy record", %{conn: conn, pharmacy: pharmacy}  do
    conn = get conn, pharmacy_path(conn, :edit, pharmacy.id)
    assert html_response(conn, 200) =~ "Edit Medicine"
  end

  test "update/2, updates a pharmacy record with valid attributes", %{conn: conn, pharmacy: pharmacy} do
    params = %{
       "drug_code" => "0001",
       "brand" => "Medicol",
       "generic_name" => "edit",
       "strength" => "1,000",
       "form" => "Capsule",
       "maximum_price" => "100"
     }
     conn = put conn, pharmacy_path(conn, :update, pharmacy.id, pharmacy: params)
     assert redirected_to(conn) == "/pharmacies"
  end

  test "delete_pharmacy/2", %{conn: conn, pharmacy: pharmacy} do
    conn = delete conn, pharmacy_path(conn, :delete_pharmacy, pharmacy.id)
    assert json_response(conn, 200) == "{\"valid\":true}"
  end
end
