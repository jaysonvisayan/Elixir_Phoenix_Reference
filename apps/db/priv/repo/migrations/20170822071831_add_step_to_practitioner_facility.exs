defmodule Innerpeace.Db.Repo.Migrations.AddStepToPractitionerFacility do
  use Ecto.Migration

  def change do
    alter table(:practitioner_facilities) do
      add :step, :integer
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)
    end
  end
end
