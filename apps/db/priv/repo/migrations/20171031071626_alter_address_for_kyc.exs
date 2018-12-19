defmodule Innerpeace.Db.Repo.Migrations.AlterAddressForKyc do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      add :kyc_bank_id, references(:kyc_banks, type: :binary_id, on_delete: :delete_all)
    end
  end
end
