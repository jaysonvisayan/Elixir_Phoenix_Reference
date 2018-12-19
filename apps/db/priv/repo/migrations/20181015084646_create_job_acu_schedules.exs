defmodule Innerpeace.Db.Repo.Migrations.CreateJobAcuSchedules do
  use Ecto.Migration

  def up do
    create table(:job_acu_schedules, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :task_count, :integer
      add :start, :utc_datetime
      add :finish, :utc_datetime
      add :request, :jsonb

      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps()
    end
  end

  def down do
    drop table(:job_acu_schedules)
  end
end
