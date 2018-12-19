defmodule Innerpeace.Db.Schemas.ProcedureUploadLog do
  use Innerpeace.Db.Schema

  schema "procedure_upload_logs" do
    field :filename, :string
    field :cpt_code, :string
    field :cpt_description, :string
    field :cpt_type, :string
    # field :payor_cpt_code, :string
    # field :payor_cpt_description, :string
    field :status, :string
    field :remarks, :string
    # field :exclusion_type, :string

    #Relationships
    belongs_to :procedure, Innerpeace.Db.Schemas.Procedure
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    # belongs_to :payor_procedure_upload_file, Innerpeace.Db.Schemas.PayorProcedureUploadFile
    belongs_to :procedure_upload_file, Innerpeace.Db.Schemas.ProcedureUploadFile

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :filename,
      :cpt_code,
      :cpt_description,
      :cpt_type,
      :status,
      :remarks,
      :created_by_id,
      :procedure_id,
      :procedure_upload_file_id
    ])
    |> validate_required([
      :filename,
      :status,
      :created_by_id,
      :procedure_upload_file_id
    ])
  end



end
