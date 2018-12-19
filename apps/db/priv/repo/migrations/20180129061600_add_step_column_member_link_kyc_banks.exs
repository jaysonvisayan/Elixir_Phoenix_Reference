defmodule Innerpeace.Db.Repo.Migrations.AddStepColumnMemberLinkKycBanks do
  use Ecto.Migration

  def change do
  	alter table(:kyc_banks) do
      add :step, :integer
    end
  end
end
