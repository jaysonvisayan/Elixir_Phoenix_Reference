defmodule Innerpeace.Db.Repo.Migrations.CreatePractitionerSchedule do
  use Ecto.Migration

  def change do
    create table(:practitioner_schedules, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :day, :string
      add :room, :string
      add :time_from, :time
      add :time_to, :time
      add :practitioner_account_id, references(:practitioner_accounts, type: :binary_id, on_delete: :delete_all)
      add :practitioner_facility_id, references(:practitioner_facilities, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
    create index(:practitioner_schedules, [:practitioner_account_id])
    create index(:practitioner_schedules, [:practitioner_facility_id])

  end
end
