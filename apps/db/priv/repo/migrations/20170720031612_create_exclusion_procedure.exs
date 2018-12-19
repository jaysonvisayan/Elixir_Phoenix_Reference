defmodule Innerpeace.Db.Repo.Migrations.CreateExclusionProcedure do
  use Ecto.Migration

  def change do
    create table(:exclusion_procedures, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :exclusion_id, references(:exclusions, type: :binary_id, on_delete: :nothing)
      add :procedure_id, references(:procedures, type: :binary_id, on_delete: :nothing)

      timestamps()
    end
    create index(:exclusion_procedures, [:exclusion_id])
    create index(:exclusion_procedures, [:procedure_id])
  end

end
