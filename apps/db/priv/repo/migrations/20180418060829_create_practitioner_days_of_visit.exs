defmodule Innerpeace.Db.Repo.Migrations.CreatePractitionerDaysOfVisit do
  use Ecto.Migration

  def change do
    create table(:practitioner_days_of_visits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :role, :string
      add :date_from, :date
      add :date_to, :date

      add :authorization_practitioner_specializaton_id, references(:authorization_practitioner_specializations, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
  end
end
