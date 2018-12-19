defmodule Innerpeace.Db.Repo.Migrations.AddGuaranteedAmountInAcuSchedule do
  use Ecto.Migration

  def change do
    alter table(:acu_schedules) do
      add :guaranteed_amount, :decimal
    end
  end
end
