defmodule Innerpeace.Db.Repo.Migrations.AddIsClaimedInAuthorization do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      add :is_claimed?, :boolean, default: false
    end
  end
end
