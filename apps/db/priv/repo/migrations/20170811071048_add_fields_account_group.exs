defmodule Innerpeace.Db.Repo.Migrations.AddFieldsInAccountGroup do
  use Ecto.Migration

  def change do
    alter table(:account_groups) do
      add :mode_of_payment, :date
      add :payee_name, :string
      add :account_no, :string
      add :account_name, :string
      add :branch, :string
    end
  end
end
