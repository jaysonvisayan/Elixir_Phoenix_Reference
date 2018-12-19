defmodule Innerpeace.Db.Repo.Migrations.AddStatusFieldInAcuMembers do
  use Ecto.Migration

  def change do
    alter table(:acu_schedule_members) do
      add :status, :string
    end
  end
end
