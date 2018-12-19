defmodule Innerpeace.Db.Repo.Migrations.CreatePermission do
  use Ecto.Migration

  def change do
    create table(:permissions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :application_id, references(:applications, type: :binary_id)
      add :name, :string
      add :status, :string
      add :description, :string
      add :module, :string
      add :keyword, :string

      timestamps()
    end
    create index(:permissions, [:application_id])
  end
end
