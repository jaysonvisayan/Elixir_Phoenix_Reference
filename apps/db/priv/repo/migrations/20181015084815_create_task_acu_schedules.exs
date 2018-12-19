defmodule Innerpeace.Db.Repo.Migrations.CreateTaskAcuSchedules do
  use Ecto.Migration

  def up do
     create table(:task_acu_schedules, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :start, :utc_datetime
      add :finish, :utc_datetime
      add :request, :jsonb
      add :result, :jsonb
      add :job_acu_schedule_id, references(:job_acu_schedules, type: :binary_id)

      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps()
     end
  end

  def down do
    drop table(:task_acu_schedules)
  end
end
