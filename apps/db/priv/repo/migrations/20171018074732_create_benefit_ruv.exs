defmodule Innerpeace.Db.Repo.Migrations.CreateBenefitRuv do
  use Ecto.Migration

  def change do
    create table(:benefit_ruvs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :benefit_id, references(:benefits, type: :binary_id, on_delete: :nothing)
      add :ruv_id, references(:ruvs, type: :binary_id, on_delete: :nothing)

      timestamps()
    end
    create index(:benefit_ruvs, [:benefit_id])
    create index(:benefit_ruvs, [:ruv_id])

  end
end
