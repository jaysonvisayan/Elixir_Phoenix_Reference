defmodule Innerpeace.Db.Schemas.BatchFile do
  use Innerpeace.Db.Schema

  schema "batch_files" do
    belongs_to :batch, Innerpeace.Db.Schemas.Batch
    belongs_to :file, Innerpeace.Db.Schemas.File
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id

    field :document_type, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :batch_id,
      :file_id,
      :created_by_id,
      :updated_by_id,
      :document_type
    ])
    |> validate_required([
      # :batch_id,
      :file_id,
      :created_by_id,
      :updated_by_id
    ])
  end
end
