defmodule Innerpeace.Db.Schemas.MemberUploadFile do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "member_upload_files" do
    field :filename, :string
    field :remarks, :string
    field :batch_no, :string
    field :upload_type, :string
    field :count, :integer

    #Relationship
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    has_many :member_upload_logs, Innerpeace.Db.Schemas.MemberUploadLog, on_delete: :delete_all
    has_many :member_cop_upload_logs, Innerpeace.Db.Schemas.MemberCOPUploadLog, on_delete: :delete_all
    has_many :member_maintenance_upload_logs, Innerpeace.Db.Schemas.MemberMaintenanceUploadLog, on_delete: :delete_all

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :batch_no,
      :filename,
      :remarks,
      :created_by_id,
      :upload_type,
      :count
    ])
    |> validate_required([
      :batch_no,
      :filename,
      :remarks,
      :created_by_id,
      :count
    ])
  end

end
