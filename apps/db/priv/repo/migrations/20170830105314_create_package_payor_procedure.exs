defmodule Innerpeace.Db.Repo.Migrations.CreatePackagePayorProcedure do
  use Ecto.Migration

  def change do
  	create table(:package_payor_procedures, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :package_id, references(:packages, type: :binary_id, on_delete: :nothing)
      add :payor_procedure_id, references(:payor_procedures, type: :binary_id, on_delete: :nothing)
      add :male, :boolean, default: false
      add :female, :boolean, default: false
      add :age_from, :integer
      add :age_to, :integer

      timestamps()

    end

      create index(:package_payor_procedures, [:package_id])
      create index(:package_payor_procedures, [:payor_procedure_id])

  end
end
