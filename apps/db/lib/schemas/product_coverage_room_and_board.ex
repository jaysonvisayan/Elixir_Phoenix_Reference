defmodule Innerpeace.Db.Schemas.ProductCoverageRoomAndBoard do
  use Innerpeace.Db.Schema

  schema "product_coverage_room_and_boards" do
    field :room_and_board, :string
    field :room_type, :string
    field :room_limit_amount, :decimal
    field :room_upgrade, :integer
    field :room_upgrade_time, :string

    belongs_to :product_coverage, Innerpeace.Db.Schemas.ProductCoverage

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(
      params, [
        :room_and_board,
        :room_type,
        :room_limit_amount,
        :room_upgrade,
        :room_upgrade_time,
        :product_coverage_id
      ])
      |> validate_required([
        :product_coverage_id
      ])
  end

  def changeset_update(struct, params \\ %{}) do
    struct
    |> cast(
      params, [
        :room_and_board,
        :room_type,
        :room_limit_amount,
        :room_upgrade,
        :room_upgrade_time,
        :product_coverage_id
      ])
      |> validate_required([
        :room_and_board,
        :product_coverage_id
      ])
  end
end
