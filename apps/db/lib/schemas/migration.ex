defmodule Innerpeace.Db.Schemas.Migration do
  use Innerpeace.Db.Schema

  schema "migrations" do
    field :is_done, :boolean
    field :module, :string
    field :count, :integer
    belongs_to :user, Innerpeace.Db.Schemas.User
    has_many :migration_notifications, Innerpeace.Db.Schemas.MigrationNotification, on_delete: :delete_all
    has_many :migration_extracted_result_logs, Innerpeace.Db.Schemas.MigrationExtractedResultLog, on_delete: :delete_all

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :is_done,
      :user_id,
      :module,
      :count
    ])
    |> validate_required([
      :is_done,
      :user_id
    ])
  end
end
