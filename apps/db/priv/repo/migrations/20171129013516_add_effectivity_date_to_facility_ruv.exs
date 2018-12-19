defmodule Innerpeace.Db.Repo.Migrations.AddEffectivityDateToFacilityRuv do
  use Ecto.Migration

  def change do
    alter table(:facility_ruvs) do
      add :effectivity_date, :date
    end
  end
end
