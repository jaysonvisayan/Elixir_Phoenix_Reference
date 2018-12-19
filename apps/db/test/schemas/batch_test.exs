defmodule Innerpeace.Db.Schemas.BatchTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Batch

  test "batch changeset with valid data" do
    f = insert(:facility)
    params = %{
      batch_no: "testbatch",
      facility_id: f.id,
      coverage: "Inpatient",
      soa_ref_no: "12",
      soa_amount: "12",
      estimate_no_of_claims: "12",
      date_received: "2018-01-10",
      date_due: "2018-02-10",
      mode_of_receiving: "mode1"
    }
    changeset = Batch.changeset(%Batch{}, params)
    assert changeset.valid?
  end

  test "step3_changeset with invalid data" do
    params = %{
      name: "name",
    }
    changeset = Batch.changeset(%Batch{}, params)
    refute changeset.valid?
  end

end
