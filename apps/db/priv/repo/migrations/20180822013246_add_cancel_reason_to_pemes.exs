defmodule Innerpeace.Db.Repo.Migrations.AddCancelReasonToPemes do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE pemes DROP CONSTRAINT pemes_member_id_fkey"
    alter table(:pemes) do
      modify :member_id, references(:members, type: :binary_id, on_delete: :nothing)
      add :cancel_reason, :string
    end
  end

  def down do
    execute "ALTER TABLE pemes DROP CONSTRAINT pemes_member_id_fkey"
    alter table(:pemes) do
      modify :member_id, references(:members, type: :binary_id, on_delete: :delete_all)
      remove :cancel_reason
    end
  end
end
