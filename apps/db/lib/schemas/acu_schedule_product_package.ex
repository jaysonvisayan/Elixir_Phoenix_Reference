defmodule Innerpeace.Db.Schemas.AcuSchedulePackage do
  @moduledoc """
    Schema and changesets for ACU Schedule Product
  """

  use Innerpeace.Db.Schema

  schema "acu_schedule_packages" do
    belongs_to :acu_schedule, Innerpeace.Db.Schemas.AcuSchedule
    belongs_to :acu_schedule_product, Innerpeace.Db.Schemas.AcuScheduleProduct
    belongs_to :package, Innerpeace.Db.Schemas.Package
    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    field :rate, :decimal
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :acu_schedule_id,
      :acu_schedule_product_id,
      :package_id,
      :rate,
      :facility_id
    ])
    |> validate_required([
      :acu_schedule_id,
      :acu_schedule_product_id,
      :package_id,
      :rate,
      :facility_id
    ])
  end

  def changeset_rate(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :rate
    ])
    |> validate_required([
      :rate
    ])
  end
end
