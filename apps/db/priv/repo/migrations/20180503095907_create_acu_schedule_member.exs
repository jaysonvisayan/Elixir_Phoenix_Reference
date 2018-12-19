defmodule Innerpeace.Db.Repo.Migrations.CreateAcuScheduleMember do
  use Ecto.Migration

  def change do
    create table(:acu_schedule_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :member_id, references(:members, type: :binary_id, on_delete: :delete_all)
      add :acu_schedule_id, references(:acu_schedules, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
    create index(:acu_schedule_members, [:member_id])
    create index(:acu_schedule_members, [:acu_schedule_id])
  end
end
