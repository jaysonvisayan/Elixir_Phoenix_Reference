defmodule Innerpeace.Db.Repo.Migrations.UniqueDiseaseCode do
  use Ecto.Migration

  def change do
    create unique_index(:diagnoses, [:code])
  end
end
