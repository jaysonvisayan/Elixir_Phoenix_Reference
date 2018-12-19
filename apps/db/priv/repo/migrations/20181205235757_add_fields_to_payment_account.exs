defmodule Innerpeace.Db.Repo.Migrations.AddFieldsToPaymentAccount do
  use Ecto.Migration

  def up do
    alter table(:payment_accounts) do
      add :bank_name, :string
      add :bank_branch, :string
    end
  end

  def down do
    alter table(:payment_accounts) do
      remove :bank_name
      remove :bank_branch
    end
  end
end
