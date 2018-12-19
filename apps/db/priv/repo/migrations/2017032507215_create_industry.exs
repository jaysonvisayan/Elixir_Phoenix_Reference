defmodule Innerpeace.Db.Repo.Migrations.CreateIndustry do
  use Ecto.Migration

  def change do
    create table(:industries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :code, :string

      timestamps()
    end
  end
end
