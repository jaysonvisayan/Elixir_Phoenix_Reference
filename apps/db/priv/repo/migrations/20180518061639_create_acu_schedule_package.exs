defmodule Innerpeace.Db.Repo.Migrations.CreateAcuSchedulePackage do
  use Ecto.Migration

  def change do

    create table(:acu_schedule_packages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :acu_schedule_id, references(:acu_schedules, type: :binary_id, on_delete: :delete_all)
      add :package_id, references(:packages, type: :binary_id, on_delete: :delete_all)
      add :rate, :decimal
      timestamps()
    end
    create index(:acu_schedule_packages, [:acu_schedule_id])
    create index(:acu_schedule_packages, [:package_id])
  end
end
