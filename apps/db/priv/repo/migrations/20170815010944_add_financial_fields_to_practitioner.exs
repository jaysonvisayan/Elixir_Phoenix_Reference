defmodule Innerpeace.Db.Repo.Migrations.AddFinancialFieldsToPractitioner do
  use Ecto.Migration

  def change do
    alter table(:practitioners) do
      add :exclusive, {:array, :string}
      add :vat_status, :string
      add :prescription_period, :string
      add :tin, :string
      add :withholding_tax, :string
      add :payment_type, :string
      add :xp_card_no, :string
      add :payee_name, :string
    end
  end
end
