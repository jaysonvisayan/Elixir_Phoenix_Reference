defmodule Innerpeace.Db.Schemas.JobAcuSchedule do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "job_acu_schedules" do
    field :type, :string
    field :task_count, :integer
    field :start, :utc_datetime
    field :finish, :utc_datetime
    field :request, :map

    belongs_to :created_by, Innerpeace.Db.Schemas.User, foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User, foreign_key: :updated_by_id

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :type,
      :start,
      :task_count,
      :finish,
      :request,
      :created_by_id,
      :updated_by_id
    ])
  end
end
