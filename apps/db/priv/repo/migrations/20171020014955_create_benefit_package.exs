defmodule Innerpeace.Db.Repo.Migrations.CreateBenefitPackage do
  use Ecto.Migration

  def change do
    create table(:benefit_packages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :benefit_id, references(:benefits, type: :binary_id, on_delete: :nothing)
      add :package_id, references(:packages, type: :binary_id, on_delete: :nothing)

      timestamps()
    end
    create index(:benefit_packages, [:benefit_id])
    create index(:benefit_packages, [:package_id])

  end
end
