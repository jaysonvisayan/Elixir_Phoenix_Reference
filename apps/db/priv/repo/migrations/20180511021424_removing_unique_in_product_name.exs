defmodule Innerpeace.Db.Repo.Migrations.RemovingUniqueInProductName do
  use Ecto.Migration

  def up do
    drop unique_index(:products, [:name])
  end

  def down do
    create unique_index(:products, [:name])
  end

end
