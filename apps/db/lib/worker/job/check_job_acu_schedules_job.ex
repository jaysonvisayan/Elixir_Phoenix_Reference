defmodule Innerpeace.Db.Worker.Job.CheckJobAcuSchedulesJob do
  @moduledoc false

  alias Innerpeace.{
    Db.Repo,
    Db.Base.AcuScheduleContext,
  }
  alias Ecto.Changeset

  def perform(job_acu_schedules_id) do
    finish = AcuScheduleContext.check_finish_date_task_acu_schedule(job_acu_schedules_id)
    AcuScheduleContext.update_job_acu_schedule(job_acu_schedules_id, finish)

    rescue
    e in ArgumentError ->
      AcuScheduleContext.update_job_acu_schedule(job_acu_schedules_id, %{finish: DateTime.utc_now()})

    DBConnection.ConnectionError ->
      AcuScheduleContext.update_job_acu_schedule(job_acu_schedules_id, %{finish: DateTime.utc_now()})

    _ ->
      AcuScheduleContext.update_job_acu_schedule(job_acu_schedules_id, %{finish: DateTime.utc_now()})
  end
end
