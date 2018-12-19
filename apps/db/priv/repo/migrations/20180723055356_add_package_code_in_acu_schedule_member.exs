defmodule Innerpeace.Db.Repo.Migrations.AddPackageCodeInAcuScheduleMember do
  use Ecto.Migration

  def change do
    alter table(:acu_schedule_members) do
      add :package_code, :string
    end
  end
end
