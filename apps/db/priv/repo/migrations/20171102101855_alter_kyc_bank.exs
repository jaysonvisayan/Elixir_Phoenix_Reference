defmodule Innerpeace.Db.Repo.Migrations.AlterKycBank do
  use Ecto.Migration

  def change do
    alter table(:kyc_banks) do
      remove (:tin)
      remove (:sss_number)
      remove (:unified_id_number)
      add :tin, :integer
      add :sss_number, :integer
      add :unified_id_number, :integer
    end
  end
end
