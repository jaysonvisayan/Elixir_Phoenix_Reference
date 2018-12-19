defmodule Innerpeace.Db.Schemas.PackageFacility do
  use Innerpeace.Db.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @timestamps_opts [usec: false]
  schema "package_facilities" do
    belongs_to :package, Innerpeace.Db.Schemas.Package
    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    field :rate, :decimal

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :package_id,
      :facility_id,
      :rate
    ])
    |> validate_required([:package_id, :facility_id])
  end
end
