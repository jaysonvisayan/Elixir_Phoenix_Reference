defmodule Innerpeace.Db.Repo.Migrations.CreatePaymentAccount do
  use Ecto.Migration

  def change do
    create table(:payment_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :bank_account, :string
      add :mode_of_payment, :string
      add :account_tin, :string
      add :vat_status, :string
      add :p_sched_of_payment, :string
      add :d_sched_of_payment, :string
      add :previous_carrier, :string
      add :attached_point, :string
      add :revolving_fund, :string
      add :threshold, :string
      add :funding_arrangement, :string
      add :authority_debit, :boolean, default: false
      add :account_group_id, references(:account_groups, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:payment_accounts, [:account_tin])
    create index(:payment_accounts, [:account_group_id])
  end
end
