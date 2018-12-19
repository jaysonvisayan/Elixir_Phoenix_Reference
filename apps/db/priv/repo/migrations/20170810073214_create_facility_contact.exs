defmodule Innerpeace.Db.Repo.Migrations.CreateFacilityContact do
  use Ecto.Migration

  def change do
    create table(:facility_contacts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :facility_id, references(:facilities, type: :binary_id, on_delete: :delete_all)
      add :contact_id, references(:contacts, type: :binary_id, on_delete: :nothing)

      timestamps()
    end

    create index(:facility_contacts, [:facility_id])
    create index(:facility_contacts, [:contact_id])
  end
end
