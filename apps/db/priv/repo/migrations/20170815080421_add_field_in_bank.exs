defmodule Innerpeace.Db.Repo.Migrations.AddFieldInBank do
  use Ecto.Migration

  def change do
    alter table(:banks) do
      add :branch, :string
    end
  end
end
