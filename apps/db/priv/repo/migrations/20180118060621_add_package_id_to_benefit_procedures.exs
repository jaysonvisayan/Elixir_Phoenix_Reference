defmodule Innerpeace.Db.Repo.Migrations.AddPackageIdToBenefitProcedures do
  use Ecto.Migration

  def change do
    alter table(:benefit_procedures) do
      add :package_id, references(:packages, type: :binary_id, on_delete: :delete_all)
    end
    create index(:benefit_procedures, [:package_id])
  end
end
