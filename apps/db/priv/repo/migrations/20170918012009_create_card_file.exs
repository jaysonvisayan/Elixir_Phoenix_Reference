defmodule Innerpeace.Db.Repo.Migrations.CreateCardFile do
  use Ecto.Migration

  def change do
    create table(:card_files, primary_key: false)  do
      add :id, :binary_id, primary_key: true
      add :fulfillment_card_id, references(:fulfillment_cards, type: :binary_id, on_delete: :delete_all)
      add :file_id, references(:files, type: :binary_id, on_delete: :delete_all)
      timestamps()
    end
    create index(:card_files, [:fulfillment_card_id, :file_id])

  end
end
