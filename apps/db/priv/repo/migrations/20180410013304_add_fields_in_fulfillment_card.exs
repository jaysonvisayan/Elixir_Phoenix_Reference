defmodule Innerpeace.Db.Repo.Migrations.AddFieldsInFulfillmentCard do
  use Ecto.Migration

  def change do
    alter table(:fulfillment_cards) do
      add :transmittal_listing, :string
      add :packaging_style, :string
    end
  end
end
