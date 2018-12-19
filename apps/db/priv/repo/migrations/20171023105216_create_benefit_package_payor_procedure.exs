defmodule Innerpeace.Db.Repo.Migrations.CreateBenefitPackagePayorProcedure do
  use Ecto.Migration

  def change do
    create table(:benefit_package_payor_procedures, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :benefit_package_id, references(:benefit_packages, type: :binary_id, on_delete: :nothing)
      add :payor_procedure_id, references(:payor_procedures, type: :binary_id, on_delete: :nothing)

      timestamps()
    end
    create index(:benefit_package_payor_procedures, [:benefit_package_id])
    create index(:benefit_package_payor_procedures, [:payor_procedure_id])

  end
end
