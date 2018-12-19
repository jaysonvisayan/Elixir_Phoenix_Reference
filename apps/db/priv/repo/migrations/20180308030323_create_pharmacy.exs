defmodule Innerpeace.Db.Repo.Migrations.CreatePharmacy do
  use Ecto.Migration

  def change do
    create table(:pharmacies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :drug_code, :string
      add :generic_name, :string
      add :brand, :string
      add :strength, :integer
      add :form, :string
      add :maximum_price, :decimal
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps()
    end
    create unique_index(:pharmacies, [:drug_code])
  end
end
