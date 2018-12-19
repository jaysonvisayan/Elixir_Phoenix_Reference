defmodule Innerpeace.Db.Schemas.MigrationExtractedResultLog do
  use Innerpeace.Db.Schema

  schema "migration_extracted_result_logs" do
    field :module, :string
    field :status_code, :string
    field :remarks, :string
    belongs_to :migration, Innerpeace.Db.Schemas.Migration

    timestamps()

  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :module,
      :status_code,
      :remarks,
      :migration_id
    ])
    |> validate_required([
      :module,
      :migration_id
    ])
  end

end
