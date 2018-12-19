defmodule Innerpeace.Db.Repo.Migrations.AddTransactionNoInAuthorization do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      add :transaction_no, :string
    end
  end
end
