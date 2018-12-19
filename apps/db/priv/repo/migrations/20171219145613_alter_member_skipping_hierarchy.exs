defmodule Innerpeace.Db.Repo.Migrations.AlterMemberSkippingHierarchy do
  use Ecto.Migration

  def change do
    alter table(:member_skipping_hierarchy) do
      add :created_by_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :updated_by_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :status, :string
      add :code, :string
    end
    create index(:member_skipping_hierarchy, [:created_by_id])
    create index(:member_skipping_hierarchy, [:updated_by_id])
  end
end
