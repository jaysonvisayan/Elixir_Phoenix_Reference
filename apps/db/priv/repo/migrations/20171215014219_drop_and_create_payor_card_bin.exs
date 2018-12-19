defmodule Innerpeace.Db.Repo.Migrations.DropAndCreatePayorCardBin do
  use Ecto.Migration

  def up do
    drop table(:payor_card_bins)

    create table(:payor_card_bins, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :card_bin, :string
      add :sequence, :integer

      add :payor_id, references(:payors, type: :binary_id)

      timestamps()
    end
  end

  def down do
    drop table(:payor_card_bins)

    create table(:payor_card_bins) do
      add :card_bin, :string
      add :limit, :integer
      add :sequence, :integer

      add :payor_id, references(:payors, type: :binary_id)

      timestamps()
    end
  end
end
