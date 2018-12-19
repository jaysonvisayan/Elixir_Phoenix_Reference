defmodule Innerpeace.Db.Repo.Migrations.CreateBenefitDiagnosis do
  use Ecto.Migration

  def change do
    create table(:benefit_diagnoses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :exclusion, :string
      add :mark, :string
      add :benefit_id, references(:benefits, type: :binary_id, on_delete: :nothing)
      add :diagnosis_id, references(:diagnoses, type: :binary_id,  on_delete: :nothing)

      timestamps()
    end
    create index(:benefit_diagnoses, [:benefit_id])
    create index(:benefit_diagnoses, [:diagnosis_id])
  end
end
