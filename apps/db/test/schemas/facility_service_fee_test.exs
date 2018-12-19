defmodule Innerpeace.Db.Schemas.FacilityServiceFeeTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.FacilityServiceFee

  test "changeset with valid attributes" do
    params = %{
      facility_id: Ecto.UUID.generate(),
      coverage_id: Ecto.UUID.generate(),
      service_type_id: Ecto.UUID.generate(),
      payment_mode: Ecto.UUID.generate(),
      rate_fixed: 200.5,
      rate_mdr: 5
    }
    changeset = FacilityServiceFee.changeset(%FacilityServiceFee{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = FacilityServiceFee.changeset(%FacilityServiceFee{})
    refute changeset.valid?
  end

end

