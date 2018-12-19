defmodule Innerpeace.Db.Schemas.MemberTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Member
  alias Ecto.UUID

  test "changeset general with valid attributes" do
    params = %{
      account_code: "some code",
      type: "Principal",
      principal_id: Ecto.UUID.generate(),
      effectivity_date: Ecto.Date.utc(),
      expiry_date: Ecto.Date.utc(),
      first_name: "test",
      middle_name: "test",
      last_name: "test",
      gender: "Male",
      civil_status: "Single",
      birthdate: "1995-12-18",
      employee_no: "123",
      date_hired: "2012-12-12",
      is_regular: false,
      regularization_date: "2017-01-01",
      tin: "test",
      philhealth: "test",
      for_card_issuance: true,
      philhealth_type: "Not Covered"
    }
    changeset = Member.changeset_general(%Member{}, params)
    assert changeset.valid?
  end

  test "changeset general with invalid attributes" do
    params = %{}
    changeset = Member.changeset_general(%Member{}, params)
    refute changeset.valid?
  end

  test "changeset contact with valid attributes" do
    params = %{
      email: "test@gmail.com",
      mobile: "123123123"
    }
    changeset = Member.changeset_contact(%Member{}, params)
    assert changeset.valid?
  end

  test "changeset contact with invalid attributes" do
    params = %{}
    changeset = Member.changeset_contact(%Member{}, params)
    assert changeset.valid?
  end

  test "changeset member info in memberlink with valid attributes" do
    params = %{
      blood_type: "sample_data",
      allergies: "sample_data",
      medication: "sample_data"
    }
    changeset = Member.changeset_memberlink_info(%Member{}, params)
    assert changeset.valid?
  end

  test "changeset memberlink info in memberlink with valid attributes" do
    params = %{
      first_name: "sample_data",
      last_name: "sample_data",
      gender: "sample_data",
      birthdate: "1995-12-18"
    }
    changeset = Member.changeset_memberlink_profile(%Member{}, params)
    assert changeset.valid?
  end

  test "changeset memberlink dependent in memberlink with valid attributes" do
    params = %{
      first_name: "sample_data",
      last_name: "sample_data",
      gender: "sample_data",
      birthdate: "1995-12-18",
      relationship: "mother"
    }
    changeset = Member.changeset_memberlink_dependent(%Member{}, params)
    assert changeset.valid?
  end

  test "changeset_enroll with valid attributes" do
    params = %{
      step: "5",
      updated_by_id: UUID.generate,
      enrollment_date: "2018-01-01",
      card_expiry_date: "2022-01-01"
    }

    result =
      %Member{}
      |> Member.changeset_enroll(params)

    assert result.valid?
  end

  test "changeset_enroll with invalid attributes" do
    params = %{
      step: "5",
      updated_by_id: UUID.generate,
      card_expiry_date: "2022-01-01"
    }

    result =
      %Member{}
      |> Member.changeset_enroll(params)

    refute result.valid?
  end
end

