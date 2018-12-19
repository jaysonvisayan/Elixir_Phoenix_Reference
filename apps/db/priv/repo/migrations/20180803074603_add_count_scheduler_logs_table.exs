defmodule Innerpeace.Db.Repo.Migrations.AddCountSchedulerLogsTable do
  use Ecto.Migration

  def up do
    alter table(:scheduler_logs) do
      add :total, :integer
    end
  end

  def down do
    alter table(:scheduler_logs) do
      remove :total
    end
  end
end
