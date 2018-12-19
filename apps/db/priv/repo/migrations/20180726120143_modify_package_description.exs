defmodule Innerpeace.Db.Repo.Migrations.ModifyPackageDescription do
  use Ecto.Migration

  def change do
    alter table(:packages) do
      modify :name, :text
    end
  end
end
