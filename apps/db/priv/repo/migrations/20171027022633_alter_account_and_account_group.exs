defmodule Innerpeace.Db.Repo.Migrations.AlterAccountAndAccountGroup do
  use Ecto.Migration

  def change do
    drop index(:account_hierarchy_of_eligible_dependents, [:account_id])

    alter table(:account_hierarchy_of_eligible_dependents) do
      remove :account_id
      add :account_group_id, references(:account_groups, type: :binary_id, on_delete: :delete_all)
    end
    create index(:account_hierarchy_of_eligible_dependents, [:account_group_id])
  end
end
