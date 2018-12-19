defmodule Innerpeace.Db.Repo.Migrations.RenameColumnInUserAccount do
  use Ecto.Migration

  def change do
    rename table(:user_accounts), :acount_group_id, to: :account_group_id
  end
end
