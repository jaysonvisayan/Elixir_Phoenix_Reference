defmodule Innerpeace.Db.Repo.Migrations.AddMemberProductIdAndProductBenefitIdInAuthorizationDiagnosis do
  use Ecto.Migration

  def change do
    alter table(:authorization_diagnosis) do
      add :product_benefit_id, references(:product_benefit_limits, type: :binary_id)
      add :member_product_id, references(:member_products, type: :binary_id)
    end
  end
end
