defmodule Innerpeace.Db.Repo.Migrations.AlterKycBanksTable do
  use Ecto.Migration

  def change do
    alter table(:kyc_banks) do
      add :street_no, :string
      add :subd_dist_town, :string
      add :residential_line, :string
      add :zip_code, :string
    end
  end
end
