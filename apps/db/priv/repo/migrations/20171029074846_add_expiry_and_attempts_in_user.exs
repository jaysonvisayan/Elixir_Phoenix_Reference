defmodule Innerpeace.Db.Repo.Migrations.AddExpiryAndAttemptsInUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :verification_expiry, :utc_datetime
      add :attempts, :integer
    end
  end
end
