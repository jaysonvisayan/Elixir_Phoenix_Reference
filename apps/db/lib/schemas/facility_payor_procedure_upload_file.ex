defmodule Innerpeace.Db.Schemas.FacilityPayorProcedureUploadFile do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "facility_payor_procedure_upload_files" do
    field :filename, :string
    field :remarks, :string
    field :batch_no, :string

    #Relationship
    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    has_many :facility_payor_procedure_upload_logs,
      Innerpeace.Db.Schemas.FacilityPayorProcedureUploadLog,
      on_delete: :delete_all

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :facility_id,
      :batch_no,
      :filename,
      :remarks,
      :created_by_id
    ])
    |> validate_required([
      :facility_id,
      :batch_no,
      :filename,
      :remarks,
      :created_by_id
    ])
  end

end
