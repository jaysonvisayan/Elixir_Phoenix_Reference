defmodule Innerpeace.Db.Repo.Migrations.CreateBenefitCoverage do
  use Ecto.Migration

  def change do
    create table(:coverage_benefits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :coverage_id, references(:coverages, type: :binary_id, on_delete: :nothing)
      add :benefit_id, references(:benefits, type: :binary_id, on_delete: :nothing)

      timestamps()
    end
    create index(:coverage_benefits, [:coverage_id])
    create index(:coverage_benefits, [:benefit_id])

  end
end
