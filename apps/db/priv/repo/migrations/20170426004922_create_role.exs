defmodule Innerpeace.Db.Repo.Migrations.CreateRole do
  use Ecto.Migration

  def up do
    create table(:roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :application_id, references(:applications, type: :binary_id, on_delete: :delete_all)
      add :name, :string
      add :description, :string
      add :status, :string
      add :created_by_id, :binary_id
      add :updated_by_id, :binary_id
      add :step, :integer, default: 1

      timestamps()
    end
    create unique_index(:roles, [:name])
    create index(:roles, [:application_id])
  end

  def down do
    drop table(:roles)
  end
end
