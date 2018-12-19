defmodule Innerpeace.Db.Repo.Migrations.ModifyUploadStatusToText do
  use Ecto.Migration

  def change do
    alter table(:member_upload_logs) do
      modify :upload_status, :text
    end
  end
end
