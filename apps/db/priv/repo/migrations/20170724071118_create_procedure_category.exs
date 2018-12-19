defmodule Innerpeace.Db.Repo.Migrations.CreateProcedureCategory do
  use Ecto.Migration

  def change do
    create table(:procedure_categories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :code, :string

      timestamps()
    end
  end
end
