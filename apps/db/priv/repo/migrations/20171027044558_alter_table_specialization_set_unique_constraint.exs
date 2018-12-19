defmodule Innerpeace.Db.Repo.Migrations.AlterTableSpecializationSetUniqueConstraint do
  use Ecto.Migration

  def change do
    create unique_index(:specializations, [:name])
  end
end
