defmodule Innerpeace.Db.Repo.Migrations.CreateDiagnosisCoverage do
  use Ecto.Migration

  def change do
    create table(:diagnosis_coverages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :diagnosis_id, references(:diagnoses, type: :binary_id, on_delete: :nothing)
      add :coverage_id, references(:coverages, type: :binary_id,  on_delete: :nothing)
      timestamps()
    end
    create index(:diagnosis_coverages, [:diagnosis_id,:coverage_id])
  end
end
