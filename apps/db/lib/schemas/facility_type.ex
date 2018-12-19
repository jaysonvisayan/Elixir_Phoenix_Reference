defmodule Innerpeace.Db.Schemas.FacilityType do
  use Innerpeace.Db.Schema

  schema "facility_types" do
    field :desc, :string

    has_many :facilities, Innerpeace.Db.Schemas.Facility
    timestamps()
  end
end
