defmodule Innerpeace.Db.Repo.Migrations.ModifyProductBenefitAddConstraint do
  use Ecto.Migration

  def change do
    create unique_index(:product_benefits, [:product_id, :benefit_id])
  end
end
