defmodule Innerpeace.Db.Repo.Migrations.CreatePractitionerContact do
  use Ecto.Migration

  def change do
    create table(:practitioner_contacts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :practitioner_id, references(:practitioners, type: :binary_id, on_delete: :delete_all)
      add :contact_id, references(:contacts, type: :binary_id, on_delete: :nothing)

      timestamps()
    end
    create index(:practitioner_contacts, [:practitioner_id])
    create index(:practitioner_contacts, [:contact_id])

  end
end
