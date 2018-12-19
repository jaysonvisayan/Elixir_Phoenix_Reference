defmodule Innerpeace.Db.Repo.Migrations.CreateAcuScheduleLogs do
  use Ecto.Migration

  def change do
    create table(:acu_schedule_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :remarks, :string
      add :member_id, references(:members, type: :binary_id, on_delete: :delete_all)
      add :acu_schedule_id, references(:acu_schedules, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
    create index(:acu_schedule_logs, [:member_id])
    create index(:acu_schedule_logs, [:acu_schedule_id])
  end
end
