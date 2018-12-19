defmodule Innerpeace.Db.Repo.Migrations.AddValidUntilToAuthorization do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      add :valid_until, :date
    end

    alter table(:authorization_benefit_packages) do
      add :package_rate, :decimal
    end
  end
end
