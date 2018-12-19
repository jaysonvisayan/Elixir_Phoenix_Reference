defmodule Innerpeace.Db.Repo.Migrations.CreateRoom do
  use Ecto.Migration

  def change do
    create table(:rooms, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :code, :string
      add :type, :string
      add :hierarchy, :integer

      timestamps()

    end

    create unique_index(:rooms, [:code])
    create unique_index(:rooms, [:type])
  end
end
