defmodule Innerpeace.Db.Schemas.PractitionerTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Practitioner

  test "changeset with valid attributes" do
    params = %{
      first_name: "role",
      last_name: "role",
      birth_date: Ecto.Date.utc(),
      effectivity_from: Ecto.Date.utc(),
      effectivity_to: Ecto.Date.utc(),
      prc_no: "description",
      phic_accredited: "Yes",
      type: ["test"],
      specialization_ids: ["488412e1-1668-42b7-86d2-bd57f46678b6"]
    }

    changeset = Practitioner.changeset(%Practitioner{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      first_name: "role",
      last_name: "role",
      birth_date: "",
      effectivity_from: Ecto.Date.utc(),
      effectivity_to: Ecto.Date.utc(),
      prc_no: "description",
      type: "status",
      specialization_ids: nil
    }

    changeset = Practitioner.changeset(%Practitioner{}, params)
    refute changeset.valid?
  end
end
