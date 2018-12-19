defmodule Innerpeace.Db.Repo.Migrations.AddFacilityIdInAcuSchedulePackages do
  use Ecto.Migration

  def change do
    alter table(:acu_schedule_packages) do
      add :facility_id, references(:facilities, type: :binary_id, on_delete: :delete_all)
    end
  end
end
