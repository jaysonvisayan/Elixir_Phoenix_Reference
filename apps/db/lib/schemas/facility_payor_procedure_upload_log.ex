defmodule Innerpeace.Db.Schemas.FacilityPayorProcedureUploadLog do
  use Innerpeace.Db.Schema

  schema "facility_payor_procedure_upload_logs" do
    field :filename, :string
    field :payor_cpt_code, :string
    field :payor_cpt_name, :string
    field :provider_cpt_code, :string
    field :provider_cpt_name, :string
    field :amount, :decimal
    field :room_code, :string
    field :discount, :decimal
    field :start_date, Ecto.Date
    field :status, :string
    field :remarks, :string

    #Relationships
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :facility_payor_procedure_upload_file, Innerpeace.Db.Schemas.FacilityPayorProcedureUploadFile

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :filename,
      :discount,
      :room_code,
      :payor_cpt_code,
      :payor_cpt_name,
      :provider_cpt_code,
      :provider_cpt_name,
      :amount,
      :start_date,
      :status,
      :remarks,
      :created_by_id,
      :facility_payor_procedure_upload_file_id
    ])
  end

end
