defmodule Innerpeace.Db.Schemas.FacilityUploadLog do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "facility_upload_logs" do
    field :filename, :string
    field :facility_code, :string
    field :facility_name, :string
    field :status, :string
    field :remarks, :string
    field :row, :integer

    #Relationships
    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :facility_upload_file, Innerpeace.Db.Schemas.FacilityUploadFile

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :filename,
      :facility_code,
      :facility_name,
      :status,
      :remarks,
      :created_by_id,
      :facility_id,
      :facility_upload_file_id,
      :row
    ])
    |> validate_required([
      :filename,
      :status,
      :created_by_id,
      :facility_upload_file_id
    ])
  end

end
