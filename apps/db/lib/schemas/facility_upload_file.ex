defmodule Innerpeace.Db.Schemas.FacilityUploadFile do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "facility_upload_files" do
    field :filename, :string
    field :remarks, :string
    field :batch_number, :string

    #Relationship
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    has_many :facility_upload_logs, Innerpeace.Db.Schemas.FacilityUploadLog, on_delete: :delete_all
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :batch_number,
      :filename,
      :remarks,
      :created_by_id
    ])
    |> validate_required([
      :filename,
      :remarks,
      :created_by_id
    ])
  end

end
