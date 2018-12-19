defmodule Innerpeace.Db.Repo.Migrations.AlterExclusionsPreExistingCondition do
  use Ecto.Migration

  def change do
    alter table(:exclusions) do
      remove (:duration_from)
      remove (:duration_to)
      add :condition, :string
    end
  end
end