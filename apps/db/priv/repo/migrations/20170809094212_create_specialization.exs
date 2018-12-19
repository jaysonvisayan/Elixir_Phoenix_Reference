defmodule Innerpeace.Db.Repo.Migrations.CreateSpecialization do
  use Ecto.Migration

  def change do
    create table(:specializations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :type, :string

      timestamps()
    end
   end
end
