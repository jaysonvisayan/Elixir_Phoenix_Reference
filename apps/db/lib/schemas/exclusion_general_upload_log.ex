defmodule Innerpeace.Db.Schemas.ExclusionGeneralUploadLog do
  use Innerpeace.Db.Schema

  schema "exclusion_general_upload_logs" do
    field :filename, :string
    field :payor_cpt_code, :string
    field :diagnosis_code, :string
    field :payor_cpt_status, :string
    field :diagnosis_status, :string
    field :payor_cpt_remarks, :string
    field :diagnosis_remarks, :string

    #Relationships
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :exclusion_general_upload_file, Innerpeace.Db.Schemas.ExclusionGeneralUploadFile

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :filename,
      :payor_cpt_code,
      :diagnosis_code,
      :payor_cpt_status,
      :diagnosis_status,
      :payor_cpt_remarks,
      :diagnosis_remarks,
      :created_by_id,
      :exclusion_general_upload_file_id
    ])
  end

end
