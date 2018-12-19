defmodule Innerpeace.Db.Repo.Migrations.AddFieldInKycBank do
  use Ecto.Migration

  def change do
  	alter table(:kyc_banks) do
      add :id_card, :string
    end
  end
end
