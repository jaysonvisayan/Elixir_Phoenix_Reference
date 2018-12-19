defmodule Innerpeace.Db.Repo.Migrations.AddAcuCoverageToBenefits do
  use Ecto.Migration

  def change do
    alter table(:benefits) do
      add :acu_coverage, :string
  	end
  end
end