defmodule Innerpeace.Db.Repo.Migrations.AddIdToAuthorizationDiagnosisAndPractitioner do
  use Ecto.Migration

  def change do
    alter table(:authorization_diagnosis) do
      add :id, :binary_id, primary_key: true
    end

    alter table(:authorization_practitioners) do
      add :id, :binary_id, primary_key: true
    end
  end
end
