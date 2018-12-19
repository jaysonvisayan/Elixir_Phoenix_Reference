defmodule Innerpeace.Db.Schemas.FacilityRUVUploadLog do
  use Innerpeace.Db.Schema

  schema "facility_ruv_upload_logs" do
    field :filename, :string
    field :ruv_code, :string
    field :ruv_description, :string
    field :ruv_type, :string
    field :value, :decimal
    field :effectivity_date, Ecto.Date
    field :status, :string
    field :remarks, :string

    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :facility_ruv_upload_file, Innerpeace.Db.Schemas.FacilityRUVUploadFile

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :filename,
      :ruv_code,
      :ruv_description,
      :ruv_type,
      :value,
      :effectivity_date,
      :status,
      :remarks,
      :created_by_id,
      :facility_ruv_upload_file_id
    ])
  end

end
