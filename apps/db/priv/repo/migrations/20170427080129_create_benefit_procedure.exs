defmodule Innerpeace.Db.Repo.Migrations.CreateBenefitProcedure do
  use Ecto.Migration

  def change do
    create table(:benefit_procedures, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :benefit_id, references(:benefits, type: :binary_id, on_delete: :nothing)
      add :procedure_id, references(:procedures, type: :binary_id, on_delete: :nothing)
      add :gender, :string
      add :age_from, :integer
      add :age_to, :integer

      timestamps()
    end
    create index(:benefit_procedures, [:benefit_id])
    create index(:benefit_procedures, [:procedure_id])

  end
end
