defmodule Innerpeace.Db.Schemas.PayorCardBinTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.PayorCardBin

  test "changeset with valid params" do
    payor = insert(:payor)
    params = %{
      payor_id: payor.id,
      card_bin: "60508311",
      sequence: 14
    }

    changeset = PayorCardBin.changeset(%PayorCardBin{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid params" do
    payor = insert(:payor)
    params = %{
      payor_id: payor.id,
      card_bin: 60_508_311,
      sequence: 14
    }

    changeset = PayorCardBin.changeset(%PayorCardBin{}, params)
    refute changeset.valid?
  end
end
