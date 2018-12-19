defmodule Innerpeace.Db.Repo.Migrations.CreateProductBenefitLimit do
  use Ecto.Migration

  def change do
    create table(:product_benefit_limits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_benefit_id, references(:product_benefits, type: :binary_id, on_delete: :nothing)
      add :benefit_limit_id, references(:benefit_limits, type: :binary_id, on_delete: :nothing)

      add :coverages, :string
      add :limit_type, :string

      add :limit_percentage, :integer
      add :limit_amount, :decimal
      add :limit_session, :integer

      add :created_by_id, :binary_id
      add :updated_by_id, :binary_id

      timestamps()
    end
    create index(:product_benefit_limits, [:product_benefit_id])
    create index(:product_benefit_limits, [:benefit_limit_id])

  end
end
