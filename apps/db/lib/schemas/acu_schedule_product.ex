defmodule Innerpeace.Db.Schemas.AcuScheduleProduct do
  @moduledoc """
    Schema and changesets for ACU Schedule Product
  """

  use Innerpeace.Db.Schema

  schema "acu_schedule_products" do

    belongs_to :acu_schedule, Innerpeace.Db.Schemas.AcuSchedule
    belongs_to :product, Innerpeace.Db.Schemas.Product

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :acu_schedule_id,
      :product_id
    ])
    |> validate_required([
      :acu_schedule_id,
      :product_id
    ])
  end
end
