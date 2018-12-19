defmodule Innerpeace.Db.Repo.Migrations.ModifyBenefitPackageAddConstraint do
  use Ecto.Migration

  def up do
    create unique_index(:benefit_packages, [:benefit_id, :package_id])
  end

  def down do
    drop unique_index(:benefit_packages, [:benefit_id, :package_id])
  end
end
