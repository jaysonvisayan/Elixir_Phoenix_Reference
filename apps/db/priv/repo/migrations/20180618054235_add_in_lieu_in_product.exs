defmodule Innerpeace.Db.Repo.Migrations.AddInLieuInProduct do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :in_lieu_of_acu, :boolean, default: false
    end
  end
end
