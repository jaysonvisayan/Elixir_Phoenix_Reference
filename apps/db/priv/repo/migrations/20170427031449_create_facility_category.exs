defmodule Innerpeace.Db.Repo.Migrations.CreateFacilityCategory do
  use Ecto.Migration

  def change do
    create table(:facility_categories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string

      timestamps()
    end
  end
end
