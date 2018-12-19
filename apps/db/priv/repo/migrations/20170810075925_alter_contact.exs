defmodule Innerpeace.Db.Repo.Migrations.AlterContact do
  use Ecto.Migration

  def change do
    alter table(:contacts) do
      add :department, :string
    end
  end
end
