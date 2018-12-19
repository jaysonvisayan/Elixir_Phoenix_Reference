defmodule Innerpeace.Db.Schemas.PractitionerSpecializationTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.PractitionerSpecialization

  test "changeset with valid attributes" do
    params = %{
      type: "asd",
      practitioner_id: "36b1b813-a89a-4f53-95cb-981f02d09f07",
      specialization_id: "36b1b813-a89a-4f53-95cb-981f02d09f07"
    }

    changeset = PractitionerSpecialization.changeset(%PractitionerSpecialization{}, params)
    assert changeset.valid?
  end
end
