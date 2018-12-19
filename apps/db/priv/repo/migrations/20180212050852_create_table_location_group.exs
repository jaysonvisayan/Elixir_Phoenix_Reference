defmodule Innerpeace.Db.Repo.Migrations.CreateTableLocationGroup do
  use Ecto.Migration

  def change do
    create table(:location_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :string
      add :step, :string
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps()
    end
  end
end
