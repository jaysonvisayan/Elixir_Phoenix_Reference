defmodule Innerpeace.Db.Repo.Migrations.AddRankToAccountProduct do
  use Ecto.Migration

  def change do
    alter table(:account_products) do
      add :rank, :integer
  	end
  end
end
