defmodule Innerpeace.Db.Schemas.FacilityContact do
  use Innerpeace.Db.Schema

  schema "facility_contacts" do
    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    belongs_to :contact, Innerpeace.Db.Schemas.Contact

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :facility_id,
      :contact_id
    ])
    |> validate_required([
      :facility_id,
      :contact_id
    ])
  end
end
