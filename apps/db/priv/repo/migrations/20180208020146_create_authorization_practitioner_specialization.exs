defmodule Innerpeace.Db.Repo.Migrations.CreateAuthorizationPractitionerSpecialization do
  use Ecto.Migration

  def change do
  	create table(:authorization_practitioner_specializations, primary_key: false) do
      add :authorization_id, references(:authorizations, type: :binary_id)
      add :practitioner_specialization_id, references(:practitioner_specializations, type: :binary_id)
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps()
    end
  end
end
