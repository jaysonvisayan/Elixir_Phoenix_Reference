defmodule Innerpeace.Db.Repo.Migrations.AddStatusFieldInAcuSchedule do
  use Ecto.Migration

  def change do
    alter table(:acu_schedules) do
      add :status, :string
    end
  end
end
