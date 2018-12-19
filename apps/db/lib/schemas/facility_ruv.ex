defmodule Innerpeace.Db.Schemas.FacilityRUV do
  use Innerpeace.Db.Schema

  @timestamps_opts [usec: false]
  schema "facility_ruvs" do

    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    belongs_to :ruv, Innerpeace.Db.Schemas.RUV

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params,
      [:facility_id,
      :ruv_id,
      ])
    |> validate_required(
      [:facility_id,
      :ruv_id,
      ])
  end
end
