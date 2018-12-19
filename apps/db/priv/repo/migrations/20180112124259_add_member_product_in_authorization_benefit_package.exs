defmodule Innerpeace.Db.Repo.Migrations.AddMemberProductInAuthorizationBenefitPackage do
  use Ecto.Migration

  def change do
    alter table(:authorization_benefit_packages) do
      add :member_product_id, references(:member_products, type: :binary_id)
      add :product_benefit_id, references(:member_products, type: :binary_id)
    end
  end
end
