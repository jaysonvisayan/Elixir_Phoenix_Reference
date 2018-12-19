defmodule Innerpeace.Db.Repo.Migrations.AddExclutionTypeToDiagnosis do
  use Ecto.Migration

  def change do
    alter table(:diagnoses) do
      add :exclusion_type, :string
    end
  end
end
