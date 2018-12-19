defmodule Innerpeace.Db.Repo.Migrations.ModifyKycBank do
  use Ecto.Migration

  def change do
    alter table(:kyc_banks) do
      remove (:tin)
      remove (:sss_number)
      remove (:unified_id_number)
      add :tin, :string
      add :sss_number,:string
      add :unified_id_number, :string
    end
  end
end
