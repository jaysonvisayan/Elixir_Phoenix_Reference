defmodule Innerpeace.Db.Repo.Migrations.AddCountryAreaLocalInPhone do
  use Ecto.Migration

  def change do
    alter table(:phones) do
      add :country_code, :string
      add :area_code, :string
      add :local, :string
    end
  end
end
