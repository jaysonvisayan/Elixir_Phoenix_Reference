defmodule Innerpeace.Db.Repo.Migrations.RemoveNotUsedColumnInFacilities do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE facilities DROP CONSTRAINT facilities_facility_category_id_fkey"

    alter table(:facilities) do
      remove :vat_status
      remove :mode_of_releasing
      remove :facility_category_id
      remove :mode_of_payment
      remove :prescription_clause
    end

  end

  def down do
    alter table(:facilities) do
      add :vat_status, :string
      add :mode_of_releasing, :string
      add :facility_category_id, references(:facility_categories, type: :binary_id)
      add :mode_of_payment, :string
      add :prescription_clause, :string
    end
  end
end
