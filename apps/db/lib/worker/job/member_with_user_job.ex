defmodule Innerpeace.Db.Worker.Job.MemberWithUserJob do
  alias Innerpeace.{
    Db.Repo,
    Db.Base.Api.MemberContext,
    Db.Base.UserContext,
    Worker.Job.NotificationJob,
    Worker.Job.CreateMemberJob
  }
  alias Innerpeace.Db.Schemas.{
    Migration,
    MigrationNotification,
  }

  alias Ecto.Changeset

  def perform(module, url_endpoint, params, members_count) do
    params["members"]
    |> Enum.map(&(
      Exq
      |> Exq.enqueue(
        "create_member_with_user_job",
        "Innerpeace.Db.Worker.Job.CreateMemberWithUserJob",
        [&1, params["migration_id"]]
      )
    ))
  end

end
