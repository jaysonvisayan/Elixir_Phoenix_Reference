defmodule Innerpeace.Db.Repo.Migrations.RemoveAccountTinConstraint do
  use Ecto.Migration

  def change do
    drop unique_index(:payment_accounts, [:account_tin])
  end
end
