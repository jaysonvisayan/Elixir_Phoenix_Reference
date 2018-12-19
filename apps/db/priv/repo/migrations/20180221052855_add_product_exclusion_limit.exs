defmodule Innerpeace.Db.Repo.Migrations.AddProductExclusionLimit do
  use Ecto.Migration

  def change do
    create table(:product_exclusion_limits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_exclusion_id, references(:product_exclusions, type: :binary_id, on_delete: :nothing)
      add :limit_type, :string
      add :limit_peso, :decimal
      add :limit_percentage, :integer
      add :limit_session, :integer
      timestamps()
    end
    create index(:product_exclusion_limits, [:product_exclusion_id])
  end

end
