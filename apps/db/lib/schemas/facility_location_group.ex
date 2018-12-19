defmodule Innerpeace.Db.Schemas.FacilityLocationGroup do
  @moduledoc false

  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :location_group
  ]}

  schema "facility_location_groups" do
    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    belongs_to :location_group, Innerpeace.Db.Schemas.LocationGroup

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :facility_id,
      :location_group_id
    ])
    |> validate_required([
      :facility_id,
      :location_group_id
    ])
  end
end
