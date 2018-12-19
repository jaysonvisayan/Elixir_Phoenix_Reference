defmodule Innerpeace.Db.Repo.Migrations.AddBatchIdToAcuSchedules do
  use Ecto.Migration

  def change do
    alter table(:acu_schedules) do
      add :batch_id, references(:batches, type: :binary_id, on_delete: :nothing)
    end
  end

end
