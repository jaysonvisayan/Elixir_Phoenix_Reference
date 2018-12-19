defmodule Innerpeace.Db.Repo.Migrations.CreateAuthorizationPractitioner do
  use Ecto.Migration

  def change do
    create table(:authorization_practitioners, primary_key: false) do
      add :authorization_id, references(:authorizations, type: :binary_id)
      add :practitioner_id, references(:practitioners, type: :binary_id)
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps()
    end
  end
end
