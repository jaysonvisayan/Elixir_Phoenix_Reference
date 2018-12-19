defmodule Innerpeace.Db.Repo.Migrations.CreateUserAccount do
  use Ecto.Migration

  def change do
    create table(:user_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :acount_group_id, references(:account_groups, type: :binary_id, on_delete: :delete_all)
      add :role, :string

      timestamps()
    end
  end
end
