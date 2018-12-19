defmodule Innerpeace.Db.Repo.Migrations.AddingCoveredAfterDurationCadPercentageAndCadAmount do
  use Ecto.Migration

  def change do

    alter table(:exclusion_durations) do
      add :covered_after_duration, :string ## Peso || Percentage
      add :cad_percentage, :integer
      add :cad_amount, :decimal
    end

  end
end
