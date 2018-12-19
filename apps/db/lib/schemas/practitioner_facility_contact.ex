defmodule Innerpeace.Db.Schemas.PractitionerFacilityContact do
  use Innerpeace.Db.Schema

  schema "practitioner_facility_contacts" do
    belongs_to :practitioner_facility, Innerpeace.Db.Schemas.PractitionerFacility
    belongs_to :contact, Innerpeace.Db.Schemas.Contact

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :practitioner_facility_id,
      :contact_id
    ])
    |> validate_required([
      :practitioner_facility_id,
      :contact_id
    ])
  end
end
