defmodule Innerpeace.Db.Repo.Migrations.CreateTranslation do
  use Ecto.Migration

  def change do
    create table(:translations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :base_value, :string
      add :translated_value, :string
      add :language, :string

      timestamps()
    end
  end
end
