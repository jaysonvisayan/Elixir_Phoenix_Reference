defmodule Innerpeace.Db.Repo.Migrations.AddFieldsToProduct do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :no_outright_denial, :boolean
      add :sop_principal, :string
      add :sop_dependent, :string
    end
  end
end
