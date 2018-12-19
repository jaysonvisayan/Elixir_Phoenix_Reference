defmodule Innerpeace.Db.Schemas.PractitionerFacilityPractitionerType do
  use Innerpeace.Db.Schema

  schema "practitioner_facility_practitioner_types" do
    field :type, :string
    belongs_to :practitioner_facility, Innerpeace.Db.Schemas.PractitionerFacility

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :type,
      :practitioner_facility_id
    ])
    |> validate_required([
      :type,
      :practitioner_facility_id
    ])
  end
end
