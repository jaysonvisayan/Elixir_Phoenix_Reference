defmodule Innerpeace.Db.Repo.Migrations.AddUniqueIndexToPackageCode do
  use Ecto.Migration

  def change do
    create unique_index(:packages, [:code])
  end
end
