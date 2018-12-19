defmodule Innerpeace.Db.Repo.Migrations.CreateTermsNConditions do
  use Ecto.Migration

  def change do
    create table(:terms_n_conditions, primary_key: false)  do
      add :id, :binary_id, primary_key: true
      add :version, :string

      timestamps()
    end
  end
end
