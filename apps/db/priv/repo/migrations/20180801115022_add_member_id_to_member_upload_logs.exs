defmodule Innerpeace.Db.Repo.Migrations.AddMemberIdToMemberUploadLogs do
  use Ecto.Migration

  def up do
    alter table(:member_upload_logs) do
      add :member_id, references(:members, type: :binary_id, on_delete: :delete_all)
    end
  end

  def down do
    execute "ALTER TABLE member_upload_logs DROP CONSTRAINT member_upload_logs_member_id_fkey"

    alter table(:member_upload_logs) do
      remove :member_id
    end
  end
end
