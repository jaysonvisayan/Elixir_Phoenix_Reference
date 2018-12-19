defmodule Innerpeace.Db.Repo.Migrations.CreateSequence do
  use Ecto.Migration

  def change do
    create table(:sequences, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :number, :string
      add :type, :string

      timestamps()
    end
  end
end
