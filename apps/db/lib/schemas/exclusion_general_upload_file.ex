defmodule Innerpeace.Db.Schemas.ExclusionGeneralUploadFile do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "exclusion_general_upload_files" do
    field :filename, :string
    field :remarks, :string
    field :batch_no, :string

    #Relationship
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    has_many :exclusion_general_upload_logs, Innerpeace.Db.Schemas.ExclusionGeneralUploadLog, on_delete: :delete_all

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :batch_no,
      :filename,
      :remarks,
      :created_by_id
    ])
    |> validate_required([
      :batch_no,
      :filename,
      :remarks,
      :created_by_id
    ])
  end

end
