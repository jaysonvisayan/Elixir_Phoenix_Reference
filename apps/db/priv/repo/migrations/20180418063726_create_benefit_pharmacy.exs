defmodule Innerpeace.Db.Repo.Migrations.CreateBenefitPharmacy do
  use Ecto.Migration

  def up do
    create table(:benefit_pharmacies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :benefit_id, references(:benefits, type: :binary_id, on_delete: :delete_all)
      add :pharmacy_id, references(:pharmacies, type: :binary_id, on_delete: :delete_all)
      ## cloning purpose
      add :drug_code, :string
      add :generic_name, :string
      add :brand, :string
      add :strength, :integer
      add :form, :string
      add :maximum_price, :decimal

      timestamps()
    end
    create index(:benefit_pharmacies, [:benefit_id])
    create index(:benefit_pharmacies, [:pharmacy_id])
  end

  def down do
    drop table(:benefit_pharmacies)
  end

end
