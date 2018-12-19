defmodule Innerpeace.Db.Repo.Migrations.CreateAccountHierarchyOfEligibleDependents do
  use Ecto.Migration

  def change do
    create table(:account_hierarchy_of_eligible_dependents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all)
      add :hierarchy_type, :string
      add :dependent, :string
      add :ranking, :integer

      timestamps()
    end

    create index(:account_hierarchy_of_eligible_dependents, [:account_id])
  end
end
