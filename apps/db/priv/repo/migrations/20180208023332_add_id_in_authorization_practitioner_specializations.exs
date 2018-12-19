defmodule Innerpeace.Db.Repo.Migrations.AddIdInAuthorizationPractitionerSpecializations do
  use Ecto.Migration

  def change do
  	alter table(:authorization_practitioner_specializations) do
      add :id, :binary_id, primary_key: true
    end
  end
end
