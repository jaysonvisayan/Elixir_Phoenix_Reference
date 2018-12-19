defmodule Innerpeace.Db.Repo.Migrations.AddUniqueIndexInProductName do
  use Ecto.Migration

  def change do
  	alter table(:products) do
      modify :name, :string
    end
    create unique_index(:products, [:name])
  end
end
