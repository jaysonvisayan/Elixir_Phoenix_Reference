defmodule Innerpeace.Db.Schemas.FacilityFile do
  use Innerpeace.Db.Schema

  schema "facility_files" do
    field :type, :string

    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    belongs_to :file, Innerpeace.Db.Schemas.File

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params,[
      :file_id,
      :facility_id,
      :type
    ])
    |> validate_required([
      :file_id,
      :facility_id,
      :type
    ])
  end

end

