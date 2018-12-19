defmodule Innerpeace.Db.Repo.Migrations.CreateExclusionDisease do
  use Ecto.Migration

  def change do
    create table(:exclusion_diseases, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :exclusion_id, references(:exclusions, type: :binary_id, on_delete: :nothing)
      add :disease_id, references(:diagnoses, type: :binary_id, on_delete: :nothing)

      timestamps()
    end
    create index(:exclusion_diseases, [:exclusion_id])
    create index(:exclusion_diseases, [:disease_id])
  end

end
