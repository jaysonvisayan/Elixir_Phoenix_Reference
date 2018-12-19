defmodule Innerpeace.Db.Repo.Migrations.ModifyAcuScheduleLogs do
  use Ecto.Migration

  def up do
    alter table(:acu_schedule_logs) do
      modify :remarks, :text
    end
  end

  def down do
    alter table(:acu_schedule_logs) do
      modify :remarks, :string
    end
  end
end
