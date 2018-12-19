defmodule Innerpeace.Db.Repo.Migrations.AddAccountGroupIdPeme do
  use Ecto.Migration

  def change do
    alter table(:pemes) do
      add :account_group_id, references(:account_groups, type: :binary_id, on_delete: :delete_all)
    end
  end
end
