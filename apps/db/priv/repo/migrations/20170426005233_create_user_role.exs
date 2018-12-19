defmodule Innerpeace.Db.Repo.Migrations.CreateUserRole do
  use Ecto.Migration

  def change do
    create table(:user_roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id)
      add :role_id, references(:roles, type: :binary_id)

      timestamps()
    end
    create unique_index(:user_roles, [:user_id, :role_id])
  end
end
