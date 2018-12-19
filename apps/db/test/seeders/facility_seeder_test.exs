defmodule Innerpeace.Db.FacilitySeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.FacilitySeeder


  test "test facility with new data" do
    dropdown = insert(:dropdown)
    user = insert(:user)
    [f1] = FacilitySeeder.seed(data(dropdown, user))
    assert f1.name ==  "MAKATI MEDICAL CENTER"
  end


  test "" do
    dropdown = insert(:dropdown)
    user = insert(:user)
    data = [
      %{
      "code" => "880000000006035",
      "name" => "MAKATI MEDICAL CENTER",
      "license_name" => "licensename1",
      "phic_accreditation_from" => "02-17-2011",
      "phic_accreditation_to" => "02-17-2011",
      "phic_accreditation_no" => "45654665",
      "status" => "I",
      "affiliation_date" =>  "02-17-2011",
      "disaffiliation_date" => "01-17-2012",
      "phone_no" => "7656734",
      "email_address" => "g@medilink.com.ph",
      #logo,
      "line_1" => "1234567",
      "line_2" => "1234568",
      "city" => "Makati",
      "province" => "Metro Manila",
      "region" => "NCR",
      "country" => "Philippines",
      "postal_code" => "1206",
      "longitude" => "32",
      "latitude" => "54",
      "tin" => "234234",
      "presription_term" => 20,
      "credit_term" => 100,
      "credit_limit" => 100,
      "no_of_beds" => "90",
      "bond" => 0.0,
      "step" => 4,
      "fcategory_id" => dropdown.id,
      "ftype_id" => dropdown.id,
      "vat_status_id" => dropdown.id,
      "prescription_clause_id" => dropdown.id,
      "payment_mode_id" => dropdown.id,
      "releasing_mode_id" => dropdown.id,
      "created_by_id" => user.id,
      "updated_by_id" => user.id
      }
    ]

    [f1] = FacilitySeeder.seed(data)
    assert f1.name ==  "MAKATI MEDICAL CENTER"

  end


  defp data(dropdown, user) do
    [
      %{
      "code" => "880000000006035",
      "name" => "MAKATI MEDICAL CENTER",
      "license_name" => "licensename1",
      "phic_accreditation_from" => "02-17-2011",
      "phic_accreditation_to" => "02-17-2011",
      "phic_accreditation_no" => "45654665",
      "status" => "I",
      "affiliation_date" =>  "02-17-2011",
      "disaffiliation_date" => "01-17-2012",
      "phone_no" => "7656734",
      "email_address" => "g@medilink.com.ph",
      #logo,
      "line_1" => "1234567",
      "line_2" => "1234568",
      "city" => "Makati",
      "province" => "Metro Manila",
      "region" => "NCR",
      "country" => "Philippines",
      "postal_code" => "1206",
      "longitude" => "32",
      "latitude" => "54",
      "tin" => "234234",
      "precription_term" => 20,
      "credit_term" => 100,
      "credit_limit" => 100,
      "no_of_beds" => "90",
      "bond" => 0.0,
      "step" => 4,
      "fcategory_id" => dropdown.id,
      "ftype_id" => dropdown.id,
      "vat_status_id" => dropdown.id,
      "prescription_clause_id" => dropdown.id,
      "payment_mode_id" => dropdown.id,
      "releasing_mode_id" => dropdown.id,
      "created_by_id" => user.id,
      "updated_by_id" => user.id
      }
    ]
  end


end
