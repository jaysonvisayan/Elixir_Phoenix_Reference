defmodule Innerpeace.Db.Repo.Migrations.CreateRolePermission do
  use Ecto.Migration

  def change do
    create table(:role_permissions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :role_id, references(:roles, type: :binary_id)
      add :permission_id, references(:permissions, type: :binary_id)

      timestamps()
    end
    create unique_index(:role_permissions, [:role_id, :permission_id])
  end
end
