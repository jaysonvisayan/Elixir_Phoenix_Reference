defmodule Innerpeace.Db.Repo.Migrations.CreateExclusionConditions do
  use Ecto.Migration

  def change do
    create table(:exclusion_conditions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :member_type, :string
      add :diagnosis_type, :string
      add :duration, :integer
      add :inner_limit, :string
      add :inner_limit_amount, :decimal
      add :within_grace_period, :boolean

      add :exclusion_id, references(:exclusions, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
  end
end
