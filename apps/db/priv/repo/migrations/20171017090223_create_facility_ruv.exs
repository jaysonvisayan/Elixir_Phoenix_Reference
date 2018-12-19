defmodule Innerpeace.Db.Repo.Migrations.CreateFacilityRuv do
  use Ecto.Migration

  def change do
    create table(:facility_ruvs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :facility_id, references(:facilities, type: :binary_id)
      add :ruv_id, references(:ruvs, type: :binary_id)
      timestamps()
    end

    create index(:facility_ruvs, [:facility_id, :ruv_id])
  end
end
