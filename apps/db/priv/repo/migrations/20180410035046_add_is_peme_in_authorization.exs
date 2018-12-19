defmodule Innerpeace.Db.Repo.Migrations.AddIsPemeInAuthorization do
  use Ecto.Migration

  def up do
    alter table(:authorizations) do
      add :is_peme?, :boolean
    end
  end

  def down do
    alter table(:authorizations) do
      remove :is_peme?
    end
  end
end
