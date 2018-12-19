defmodule Innerpeace.Db.Repo.Migrations.AccountGroupApproval do
  use Ecto.Migration

  def change do
    create table(:account_group_approvals, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_group_id, references(:account_groups, type: :binary_id, on_delete: :delete_all)
      add :name, :string
      add :department, :string
      add :designation, :string
      add :telephone, :string
      add :mobile, :string
      add :email, :string

      timestamps()
    end
    create index(:account_group_approvals, [:account_group_id])
  end
end
