defmodule Innerpeace.Db.Base.FacilityContextTest do
  use Innerpeace.Db.PayorRepo, :context
  use Innerpeace.{
    Db.SchemaCase,
  }

  # alias Innerpeace.Db.Schemas.{
  #   Contact,
  # }

  test "create_fcontact with valid attributes" do
    # Setup
    params = %{
      first_name: "Janna Mamer",
      last_name: "Dela Cruz",
      department: "SDDD",
      designation: "TL"
    }

    # Logic
    {status, result} = create_fcontact(params)

    # Assertion
    assert status == :ok
    assert result.first_name == "Janna Mamer"
  end

  test "create_fcontact with invalid attributes" do
    # Setup
    params = %{}

    # Logic
    {status, result} = create_fcontact(params)

    # Assertion
    assert status == :error
    refute result.valid?
  end
end
