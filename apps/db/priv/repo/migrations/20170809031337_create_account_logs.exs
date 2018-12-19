defmodule Innerpeace.Db.Repo.Migrations.CreateAccountLogs do
  use Ecto.Migration

  def change do
    create table(:account_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :bank_id, references(:banks, type: :binary_id, on_delete: :nothing)
      add :account_group_address_id, references(:account_group_address, type: :binary_id, on_delete: :nothing)
      add :contact_id, references(:contacts, type: :binary_id, on_delete: :nothing)
      add :account_group_id, references(:account_groups, type: :binary_id, on_delete: :nothing)
      add :account_id, references(:accounts, type: :binary_id, on_delete: :nothing)
      add :payment_account_id, references(:accounts, type: :binary_id, on_delete: :nothing)
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :message, :text

      timestamps()
    end
    create index(:account_logs, [:contact_id])
    create index(:account_logs, [:account_group_id])
    create index(:account_logs, [:account_id])
    create index(:account_logs, [:user_id])
  end
end
