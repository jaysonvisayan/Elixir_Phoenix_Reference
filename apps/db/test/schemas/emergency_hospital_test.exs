defmodule Innerpeace.Db.Schemas.EmergencyHospitalTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.EmergencyHospital

  test "changeset with valud attributes" do
    member = insert(:member)
    insert(:contact)
    params = %{
      member_id: member.id,
      name: "hospital_name",
      hmo: "example_hmo",
      phone: "12345678900",
      card_number: 234234,
      customer_care_number: 1231234,
      policy_number: 454646412
    }
    changeset = EmergencyHospital.changeset(%EmergencyHospital{}, params)
    assert changeset.valid?
  end

  test "test changeset with invalid attributes" do
    params = %{
      name: "hospital_name",
      hmo: "example_hmo",
      phone: "1234554",
      card_number: "example_number",
      customer_care_number: "example_number",
      policy_number: "1312444"
    }
    changeset = EmergencyHospital.changeset(%EmergencyHospital{}, params)
    refute changeset.valid?
  end
end
