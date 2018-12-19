defmodule Innerpeace.Db.Repo.Migrations.CreateExclusionDuration do
  use Ecto.Migration

  def change do
    create table(:exclusion_durations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :exclusion_id, references(:exclusions, type: :binary_id, on_delete: :nothing)
      add :disease_type, :string
      add :duration, :integer
      add :percentage, :integer

      timestamps()
    end
    create index(:exclusion_durations, [:exclusion_id])
  end

end
