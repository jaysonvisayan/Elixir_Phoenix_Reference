defmodule Innerpeace.Db.Repo.Migrations.CreateProductCoverageRoomAndBoard do
  use Ecto.Migration

  def change do
    create table(:product_coverage_room_and_boards, primary_key: false) do
      add :room_and_board, :string
      add :room_type, :string
      add :room_limit_amount, :decimal
      add :room_upgrade, :integer
      add :room_upgrade_time, :string

      add :product_coverage_id, references(:product_coverages, type: :binary_id, on_delete: :delete_all)
      timestamps()
    end
    create index(:product_coverage_room_and_boards, [:product_coverage_id])
  end
end
