defmodule Innerpeace.Db.Schemas.AcuScheduleLog do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "acu_schedule_logs" do
    field :remarks, :string

    belongs_to :member, Innerpeace.Db.Schemas.Member
    belongs_to :acu_schedule, Innerpeace.Db.Schemas.AcuSchedule

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
        :remarks,
        :member_id,
        :acu_schedule_id
      ])
  end

end
