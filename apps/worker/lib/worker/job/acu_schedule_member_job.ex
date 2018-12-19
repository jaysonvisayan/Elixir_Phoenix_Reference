defmodule Innerpeace.Worker.Job.AcuScheduleMemberJob do
  @moduledoc "This module generates balancing file at the end of the day"

  alias Innerpeace.Db.Base.AcuScheduleContext
  # alias Innerpeace.Db.Base.WorkerErrorLogContext

  def perform(acu_schedule_id, member_id, user_id, token, coverage_id, job_acu_schedule_id, task_acu_sched_id) do
    AcuScheduleContext.create_acu_loa(user_id, member_id, acu_schedule_id, token, coverage_id, task_acu_sched_id)
    rescue
    e in ArgumentError ->
      insert_acu_log(acu_schedule_id, member_id, "ArgumentError when inserting LOA")
      update_task_acu_schedule(task_acu_sched_id, user_id, "ArgumentError when inserting LOA")
    DBConnection.ConnectionError ->
      insert_acu_log(acu_schedule_id, member_id, "DBConnectionError when inserting LOA")
      update_task_acu_schedule(task_acu_sched_id, user_id, "DBConnectionError when inserting LOA")
    _ ->
      insert_acu_log(acu_schedule_id, member_id, "Last catcher error")
      update_task_acu_schedule(task_acu_sched_id, user_id, "Last catcher error")
  end

  defp insert_acu_log(acu_schedule_id, member_id, message) do
    acu_schedule_id
    |> AcuScheduleContext.log_params(member_id, message)
    |> AcuScheduleContext.insert_acu_log()
  end

  defp insert_task_acu_schedule(request, job_acu_schedule_id, user_id) do
    job_acu_schedule_id
    |> AcuScheduleContext.task_acu_schedule_params(user_id, request)
    |> AcuScheduleContext.insert_task_acu_schedule()
  end

  defp update_task_acu_schedule(task_acu_sched_id, user_id, result) do
    task_acu_sched = AcuScheduleContext.get_task_acu_schedule_by_id(task_acu_sched_id)
    params =
      user_id
      |> AcuScheduleContext.task_acu_schedule_update_params(result)
      |> AcuScheduleContext.update_task_acu_schedule(task_acu_sched)
  end

  defp setup_logs_params(member_id, acu_schedule_id, user_id, error_description) do
    %{
      job_name: "acu_schedule_member_job",
      job_params: "member_id: #{member_id}, acu_schedule_id: #{acu_schedule_id}, user_id: #{user_id}",
      module_name: "Acu Schedule",
      function_name: "create_acu_loa",
      error_description: error_description
    }
  end
end
