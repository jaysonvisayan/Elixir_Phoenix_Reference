defmodule Innerpeace.Db.Repo.Migrations.CreateDropdown do
  use Ecto.Migration

  def change do
    create table(:dropdowns, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :text, :string
      add :value, :string

      timestamps()
    end

    create unique_index(:dropdowns, [
      :type,
      :text,
      :value
    ])
  end
end
