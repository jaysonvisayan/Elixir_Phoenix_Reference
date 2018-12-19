defmodule Innerpeace.Db.Repo.Migrations.ChangeFlogsRemarksToText do
  use Ecto.Migration

  def change do
    alter table(:facility_upload_logs) do
      modify :remarks, :text
    end
  end
end
