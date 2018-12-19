defmodule Innerpeace.Db.Repo.Migrations.AddFixedToPractitionerFacility do
  use Ecto.Migration

  def change do
    alter table(:practitioner_facilities) do
      add :fixed, :boolean
      add :fixed_fee, :decimal
    end

    create index(:practitioner_facilities, [:facility_id])
  end
end
