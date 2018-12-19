defmodule Innerpeace.Db.Repo.Migrations.AddFieldsToFacility do
  use Ecto.Migration

  def change do
    alter table(:facilities) do
      add :payee_name, :string
      add :withholding_tax, :string
      add :bank_account_no, :string
      add :balance_biller, :boolean
      add :authority_to_credit, :boolean
    end
  end

end

