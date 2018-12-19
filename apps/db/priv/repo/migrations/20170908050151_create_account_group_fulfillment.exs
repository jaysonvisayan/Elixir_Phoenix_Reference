defmodule Innerpeace.Db.Repo.Migrations.CreateAccountGroupFulfillment do
  use Ecto.Migration

  def change do
     create table(:account_group_fulfillments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_group_id, references(:account_groups, type: :binary_id)
      add :fulfillment_id, references(:fulfillment_cards, type: :binary_id)

      timestamps()
    end
    create index(:account_group_fulfillments, [:account_group_id, :fulfillment_id])

  end
end
