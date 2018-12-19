defmodule Innerpeace.Db.Repo.Migrations.AddTimeFieldsInAcuSchedule do
  use Ecto.Migration

  def up do
    alter table(:acu_schedules) do
      add :cluster_id, references(:clusters, type: :binary_id, on_delete: :delete_all)
      add :time_from, :time
      add :time_to, :time
    end
  end

  def down do
    alter table(:acu_schedules) do
      remove :cluster_id
      remove :time_from
      remove :time_to
    end
  end
end
