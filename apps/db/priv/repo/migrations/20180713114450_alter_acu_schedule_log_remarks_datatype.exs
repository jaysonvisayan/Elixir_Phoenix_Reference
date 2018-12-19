defmodule Innerpeace.Db.Repo.Migrations.AlterAcuScheduleLogRemarksDatatype do
  use Ecto.Migration

  def up do
    alter table(:acu_schedule_logs) do
      modify :remarks, :text
    end
  end
end
