defmodule Innerpeace.Db.Base.SchedulerContext do
  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.SchedulerLog
  }

  def insert_scheduler_logs(params) do
    %SchedulerLog{}
    |> SchedulerLog.changeset(params)
    |> Repo.insert()
  end

end
