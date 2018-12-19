defmodule Innerpeace.Db.Repo.Migrations.CreateAccountGroupContact do
  use Ecto.Migration

  def change do
    create table(:account_group_contacts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :string
      add :type, :string
      add :account_group_id, references(:account_groups, type: :binary_id, on_delete: :delete_all)
      add :contact_id, references(:contacts, type: :binary_id, on_delete: :nothing)

      timestamps()
    end
    create index(:account_group_contacts, [:account_group_id])
    create index(:account_group_contacts, [:contact_id])
  end
end
