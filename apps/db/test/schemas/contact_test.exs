defmodule Innerpeace.Db.Schemas.ContactTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Contact

  test "changeset with valid attributes" do
    params = %{
      type: "Contact Person",
      last_name: "Raymond Navarro",
      designation: "Software Engineer",
      # type: "Company Address",
      email: "admin@example.com",
      ctc: "ctc",
      ctc_date_issued: "2017-01-01",
      ctc_place_issued: "Place",
      passport_no: "101",
      passport_date_issued: "2017-01-10",
      passport_place_issued: "Place",
      mobile: ["09210052020", "09210050000"],
      telephone: ["6363", "6364"]
    }

    changeset = Contact.changeset(%Contact{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      first_name: "ad",
      last_name: "payor",
      designation: "aor"
    }

    changeset = Contact.changeset(%Contact{}, params)
    refute changeset.valid?
  end

  test "changeset member_emergency_contact with valid attributes" do
    params = %{
      last_name: "sample_data",
      first_name: "sample_data",
      middle_name: "sample_data",
      relationship: "sample_data"
    }

    changeset = Contact.member_emergency_contact_changeset(%Contact{}, params)
    assert changeset.valid?
  end

end
