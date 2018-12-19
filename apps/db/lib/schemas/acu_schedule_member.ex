defmodule Innerpeace.Db.Schemas.AcuScheduleMember do
  @moduledoc """
    Schema and changesets for ACU Schedule Product
  """

  use Innerpeace.Db.Schema

  schema "acu_schedule_members" do
    field :status, :string
    field :package_code, :string
    belongs_to :acu_schedule, Innerpeace.Db.Schemas.AcuSchedule
    belongs_to :member, Innerpeace.Db.Schemas.Member

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :acu_schedule_id,
      :member_id,
      :status,
      :package_code
    ])
    |> validate_required([
      :acu_schedule_id,
      :member_id
    ])
  end
end
