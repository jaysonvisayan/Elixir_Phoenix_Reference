defmodule Innerpeace.Db.Repo.Migrations.CreateProcedure do
  use Ecto.Migration

  def change do
    create table(:procedures, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :code, :string
      add :name, :string
      add :type, :string

      timestamps()
    end
  end
end
