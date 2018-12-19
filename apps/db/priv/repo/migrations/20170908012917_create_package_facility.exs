defmodule Innerpeace.Db.Repo.Migrations.CreatePackageFacility do
  use Ecto.Migration

  def change do
  	create table(:package_facilities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :package_id, references(:packages, type: :binary_id, on_delete: :nothing)
      add :facility_id, references(:facilities, type: :binary_id, on_delete: :nothing)
      add :rate, :decimal

      timestamps()

    end

      create index(:package_facilities, [:package_id])
      create index(:package_facilities, [:facility_id])

  end
end
