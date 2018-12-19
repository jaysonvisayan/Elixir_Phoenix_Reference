defmodule Innerpeace.Db.Repo.Migrations.AlterTableAddIdInPcrnb do
  use Ecto.Migration

  def change do
    alter table(:product_coverage_room_and_boards) do
      add :id, :binary_id, primary_key: true
    end
  end
end
