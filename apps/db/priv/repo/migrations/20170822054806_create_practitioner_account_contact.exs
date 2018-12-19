defmodule Innerpeace.Db.Repo.Migrations.CreatePractitionerAccountContact do
  use Ecto.Migration

  def change do
    create table(:practitioner_account_contacts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :practitioner_account_id, references(:practitioner_accounts, type: :binary_id, on_delete: :delete_all)
      add :contact_id, references(:contacts, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
    create index(:practitioner_account_contacts, [:practitioner_account_id])
    create index(:practitioner_account_contacts, [:contact_id])

  end
end
