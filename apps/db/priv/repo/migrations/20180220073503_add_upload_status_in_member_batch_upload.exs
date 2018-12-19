defmodule Innerpeace.Db.Repo.Migrations.AddUploadStatusInMemberBatchUpload do
  use Ecto.Migration

  def change do
    alter table(:member_upload_logs) do
      add :upload_status, :string
    end
  end
end
