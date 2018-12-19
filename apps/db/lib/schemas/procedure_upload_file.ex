defmodule Innerpeace.Db.Schemas.ProcedureUploadFile do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "procedure_upload_files" do
    field :filename, :string
    field :remarks, :string
    field :batch_number, :string

    #Relationship
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    # has_many :payor_procedure_upload_logs, Innerpeace.Db.Schemas.PayorProcedureUploadLog, on_delete: :delete_all
    has_many :procedure_upload_logs, Innerpeace.Db.Schemas.ProcedureUploadLog, on_delete: :delete_all
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
