defmodule Innerpeace.Db.Repo.Migrations.CreateRoleApplication do
  use Ecto.Migration

  def change do
    create table(:role_applications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :role_id, references(:roles, type: :binary_id)
      add :application_id, references(:applications, type: :binary_id)

      timestamps()
    end
    create index(:role_applications, [:role_id, :application_id])
  end
end
