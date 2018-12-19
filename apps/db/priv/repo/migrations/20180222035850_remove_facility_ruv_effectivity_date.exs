defmodule Innerpeace.Db.Repo.Migrations.RemoveFacilityRuvEffectivityDate do
  use Ecto.Migration

  def change do
    alter table(:facility_ruvs) do
      remove (:effectivity_date)
    end
  end
end
