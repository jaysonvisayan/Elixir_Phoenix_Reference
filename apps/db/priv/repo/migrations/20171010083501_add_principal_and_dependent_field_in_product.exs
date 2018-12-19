defmodule Innerpeace.Db.Repo.Migrations.AddPrincipalAndDependentFieldInProduct do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :nem_principal, :integer
      add :nem_dependent, :integer
    end
  end
end
