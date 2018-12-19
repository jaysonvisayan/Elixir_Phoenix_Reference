defmodule Innerpeace.Db.Repo.Migrations.CreateCoverage do
  use Ecto.Migration

  def change do
    create table(:coverages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :string
      add :status, :string
      add :type, :string
      add :plan_type, :string

      timestamps()
    end
  end
end
