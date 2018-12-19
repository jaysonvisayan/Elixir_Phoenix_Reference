defmodule Innerpeace.Db.Repo.Migrations.AlterAccountGroupAddressFields do
  use Ecto.Migration

  def change do
    alter table(:account_group_address) do
      remove :unit_no
      remove :building_name
      remove :street
      remove :district
      remove :category

      add :line_1, :string
      add :line_2, :string
    end
  end
end
