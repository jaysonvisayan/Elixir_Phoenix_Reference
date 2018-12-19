defmodule Innerpeace.Db.Repo.Migrations.CreateBenefitLimits do
  use Ecto.Migration

  def change do
    create table(:benefit_limits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :benefit_id, references(:benefits, type: :binary_id, on_delete: :nothing)
      add :limit_type, :string
      add :limit_percentage, :integer
      add :limit_amount, :decimal
      add :limit_session, :integer
      add :coverages, :string

      add :created_by_id, :binary_id
      add :updated_by_id, :binary_id

      timestamps()
    end
    create index(:benefit_limits, [:benefit_id])

  end
end
