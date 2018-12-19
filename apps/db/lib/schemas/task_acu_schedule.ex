defmodule Innerpeace.Db.Schemas.TaskAcuSchedule do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "task_acu_schedules" do
    field :start, :utc_datetime
    field :finish, :utc_datetime
    field :request, :map
    field :result, :map

    belongs_to :job_acu_schedules, Innerpeace.Db.Schemas.JobAcuSchedule, foreign_key: :job_acu_schedule_id
    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :start,
      :finish,
      :request,
      :result,
      :job_acu_schedule_id,
      :created_by_id,
      :updated_by_id
    ])
  end

  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :finish,
      :result,
      :updated_by_id
    ])
  end
end
