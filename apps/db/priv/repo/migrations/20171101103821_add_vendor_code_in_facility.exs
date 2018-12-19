defmodule Innerpeace.Db.Repo.Migrations.AddVendorCodeInFacility do
  use Ecto.Migration

  def change do
    alter table(:facilities) do
      add :vendor_code, :string
    end
  end
end
