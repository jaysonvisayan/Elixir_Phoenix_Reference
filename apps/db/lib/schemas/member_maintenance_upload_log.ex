defmodule Innerpeace.Db.Schemas.MemberMaintenanceUploadLog do
  @moduledoc false

  use Innerpeace.Db.Schema
  schema "member_maintenance_upload_logs" do
    field :member_name, :string
    field :member_id, :string
    field :employee_no, :string
    field :card_no, :string
    field :maintenance_date, :string
    field :reason, :string
    field :new_effective_date, :string
    field :new_expiry_date, :string
    field :remarks, :string
    field :status, :string

    #Relationships
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :member_upload_file, Innerpeace.Db.Schemas.MemberUploadFile

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :member_upload_file_id,
      :member_name,
      :member_id,
      :employee_no,
      :card_no,
      :maintenance_date,
      :reason,
      :remarks,
      :status,
      :new_effective_date,
      :new_expiry_date,
      :created_by_id
    ])
  end
end
