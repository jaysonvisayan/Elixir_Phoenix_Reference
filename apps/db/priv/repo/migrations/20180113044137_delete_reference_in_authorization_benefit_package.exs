defmodule Innerpeace.Db.Repo.Migrations.DeleteReferenceInAuthorizationBenefitPackage do
  use Ecto.Migration

  def change do
    alter table(:authorization_benefit_packages) do
      remove :product_benefit_id
      add :product_benefit_id, references(:product_benefits, type: :binary_id)
    end
  end
end
