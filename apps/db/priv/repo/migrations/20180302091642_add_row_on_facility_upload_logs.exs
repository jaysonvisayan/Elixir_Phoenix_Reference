defmodule Innerpeace.Db.Repo.Migrations.AddRowOnFacilityUploadLogs do
  use Ecto.Migration

  def change do
    alter table(:facility_upload_logs) do
      add :row, :integer
    end
  end
end
