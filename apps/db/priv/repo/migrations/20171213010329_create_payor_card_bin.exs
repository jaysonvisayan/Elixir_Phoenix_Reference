defmodule Innerpeace.Db.Repo.Migrations.CreatePayorCardBin do
  use Ecto.Migration

  def up do
    create table(:payor_card_bins) do
      add :card_bin, :string
      add :limit, :integer
      add :sequence, :integer

      add :payor_id, references(:payors, type: :binary_id)

      timestamps()
    end
  end

  def down do
    drop table(:payor_card_bins)
  end
end
