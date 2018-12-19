defmodule Innerpeace.Db.Repo.Migrations.AlterMemberUploadLogs do
  use Ecto.Migration

  def change do
    alter table(:member_upload_logs) do
      add :tin_no, :string
      add :philhealth, :string
      add :philhealth_no, :string
    end
  end
end
