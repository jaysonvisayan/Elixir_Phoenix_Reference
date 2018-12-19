defmodule Innerpeace.Db.Repo.Migrations.CreateFacilityFiles do
  use Ecto.Migration

  def change do
    create table(:facility_files, primary_key: false)  do
      add :id, :binary_id, primary_key: true
      add :facility_id, references(:facilities, type: :binary_id, on_delete: :delete_all)
      add :file_id, references(:files, type: :binary_id, on_delete: :delete_all)
      add :type, :string
      timestamps()
    end
    create index(:facility_files, [:facility_id])
    create index(:facility_files, [:file_id])
  end
end
