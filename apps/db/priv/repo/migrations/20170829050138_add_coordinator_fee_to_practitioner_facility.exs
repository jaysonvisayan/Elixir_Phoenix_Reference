defmodule Innerpeace.Db.Repo.Migrations.AddCoordinatorFeeToPractitionerFacility do
  use Ecto.Migration

  def change do
    alter table(:practitioner_facilities) do
      add :coordinator_fee, :decimal
    end
  end
end
