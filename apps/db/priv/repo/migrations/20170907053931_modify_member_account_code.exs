defmodule Innerpeace.Db.Repo.Migrations.ModifyMemberAccountCode do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE members DROP CONSTRAINT members_account_code_fkey"

    alter table(:members) do
      modify :account_code, references(:account_groups, column: :code, type: :string, on_delete: :delete_all)
    end

  end
end
