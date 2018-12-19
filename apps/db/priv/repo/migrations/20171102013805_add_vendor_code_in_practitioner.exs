defmodule Innerpeace.Db.Repo.Migrations.AddVendorCodeInPractitioner do
  use Ecto.Migration

  def change do
    alter table(:practitioners) do
      add :vendor_code, :string
    end
  end
end
