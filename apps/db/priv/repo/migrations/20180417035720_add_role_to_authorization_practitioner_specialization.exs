defmodule Innerpeace.Db.Repo.Migrations.AddRoleToAuthorizationPractitionerSpecialization do
  use Ecto.Migration

  def up do
    alter table(:authorization_practitioner_specializations) do
      add :role, :string
    end
  end

  def down do
    alter table(:authorization_practitioner_specializations) do
      remove :role
    end
  end
end
