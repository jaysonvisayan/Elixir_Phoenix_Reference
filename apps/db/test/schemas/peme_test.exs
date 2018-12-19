defmodule Innerpeace.Db.Schemas.PemeTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Peme
  alias Ecto.UUID

  test "changeset with valid attributes" do
    params = %{
      type: "single",
      request_date: Ecto.DateTime.utc(),
      date_from: Ecto.DateTime.utc(),
      date_to: Ecto.Date.utc(),
      facility_id: UUID.bingenerate(),
      package_id: UUID.bingenerate(),
      member_id: UUID.bingenerate(),
      evoucher_number: "sample data",
      evoucher_qrcode: "sample data",
      account_group_id: UUID.generate()
    }

    changeset =
      %Peme{}
      |> Peme.changeset(params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      type: "single",
      request_date: Ecto.Date.utc(),
      date_to: Ecto.Date.utc(),
      facility_id: UUID.generate(),
      package_id: UUID.generate()
    }

    changeset =
      %Peme{}
      |> Peme.changeset(params)

    refute changeset.valid?
  end
end
