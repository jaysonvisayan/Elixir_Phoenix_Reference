defmodule Innerpeace.Db.Repo.Migrations.AddFieldsInExclusions do
  use Ecto.Migration

  def change do
    alter table(:exclusions) do
      add :is_applicability_dependent, :boolean, default: false
      add :is_applicability_principal, :boolean, default: false
    end
  end
end
