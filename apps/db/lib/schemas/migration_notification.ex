defmodule Innerpeace.Db.Schemas.MigrationNotification do
  use Innerpeace.Db.Schema

  schema "migration_notifications" do
    field :is_success, :boolean
    field :details, :string
    field :is_fetch, :boolean
    field :result, :string
    field :migration_details, :string
    field :json_params, :map
    belongs_to :migration, Innerpeace.Db.Schemas.Migration

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :is_success,
      :details,
      :is_fetch,
      :migration_id,
      :result,
      :migration_details,
      :json_params
    ])
    |> validate_required([
      :details,
      :is_fetch,
      :migration_id,
    ])
  end
end
