defmodule Innerpeace.Db.Repo.Migrations.AlterKycAddingCountryOfBirthAndCityOfBirthField do
  use Ecto.Migration

  def change do

    alter table(:kyc_banks) do
      add :country_of_birth, :string
      add :city_of_birth, :string
    end

  end
end
