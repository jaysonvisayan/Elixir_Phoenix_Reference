defmodule Innerpeace.Db.Repo.Migrations.AddNoOfSelectedMembersFieldInAcuSchedule do
  use Ecto.Migration

  def change do
    alter table(:acu_schedules) do
      add :no_of_selected_members, :integer
    end
  end
end
