defmodule Innerpeace.Db.Repo.Migrations.AddColumnsInProduct do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :dental_funding_arrangement, :string
      add :loa_validity, :string
      add :loa_validity_type, :string
      add :special_handling_type, :string
      add :type_of_payment_type, :string
    end
  end
end