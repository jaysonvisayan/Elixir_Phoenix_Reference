defmodule Innerpeace.Db.Repo.Migrations.CreateBalancingFile do
  use Ecto.Migration

  def change do
    create table(:balancing_files, primary_key: false)  do
      add :id, :binary_id, primary_key: true
      add :file, :string
      add :name, :string

      timestamps()
    end
  end
end
