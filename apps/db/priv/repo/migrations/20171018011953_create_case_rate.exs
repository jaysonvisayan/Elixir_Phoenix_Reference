defmodule Innerpeace.Db.Repo.Migrations.CreateCaseRate do
  use Ecto.Migration

  def change do
  	create table(:case_rates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :description, :string
      add :hierarchy, :integer
      add :discount_percentage, :integer

      add :created_by_id, :binary_id
      add :updated_by_id, :binary_id

      add :diagnosis_id, references(:diagnoses, type: :binary_id, on_delete: :nothing)
      add :ruv_id, references(:ruvs, type: :binary_id, on_delete: :nothing)

      timestamps()
    end

      create index(:case_rates, [:diagnosis_id])
      create index(:case_rates, [:ruv_id])

  end
end
