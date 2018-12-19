defmodule Innerpeace.Db.Repo.Migrations.AddFieldToPaymentAccount do
  use Ecto.Migration

  def change do
    alter table(:payment_accounts) do
      add :payee_name, :string
    end
  end
end
