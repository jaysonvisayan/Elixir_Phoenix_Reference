defmodule Innerpeace.Db.Repo.Migrations.CreateExclusions do
  use Ecto.Migration

  def change do
    create table(:exclusions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :coverage, :string
      add :code, :string
      add :name, :string
      add :duration_from, :date
      add :duration_to, :date

      timestamps()
    end

    create unique_index(:exclusions, [:code])
    create unique_index(:exclusions, [:name])

  end
end
