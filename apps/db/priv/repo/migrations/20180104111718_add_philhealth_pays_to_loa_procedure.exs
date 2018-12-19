defmodule Innerpeace.Db.Repo.Migrations.AddPhilhealthPaysToLoaProcedure do
  use Ecto.Migration

  def change do
    alter table(:authorization_procedure_diagnoses) do
      add :philhealth_pay, :decimal
      add :member_product_id, references(:member_products, type: :binary_id)
    end
  end
end
