defmodule Innerpeace.Db.Repo.Migrations.AddMdedPrincipalAndMdedDependentToProductTbl do
  use Ecto.Migration

  def up do
    alter table(:products) do
      add :mded_principal, :string
      add :mded_dependent, :string
    end
  end

  def down do
    alter table(:products) do
      remove :mded_principal
      remove :mded_dependent
    end
  end
end
