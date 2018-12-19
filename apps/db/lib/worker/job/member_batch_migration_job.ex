defmodule Innerpeace.Db.Worker.Job.MemberBatchMigrationJob do
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

  def perform(module, url_endpoint, params, user_id, members_count) do
    user =
      user_id
      |> UserContext.get_user!

    Enum.map(params["members"], fn(member)->
      Exq
      |> Exq.enqueue(
        "create_member_job",
        "Innerpeace.Db.Worker.Job.CreateMemberJob",
        [member, params["migration_id"]]
      )
    end)

    notifier(module, url_endpoint, params, members_count)
  end

  def notifier(module, url_endpoint, params, members_count) when members_count == 0, do: nil
  def notifier(module, url_endpoint, params, members_count) when members_count <= 5  do
    Exq
    |> Exq.enqueue_in(
      "notification_job", 3,
      "Innerpeace.Db.Worker.Job.NotificationJob",
      [module, url_endpoint, params["migration_id"], members_count, 0]
    )
  end

  def notifier(module, url_endpoint, params, members_count) do
    # one_hour = 3600# sec
    Exq
    |> Exq.enqueue_in(
      "notification_job", 60,
      "Innerpeace.Db.Worker.Job.NotificationJob",
      [module, url_endpoint, params["migration_id"], members_count, 0]
    )
  end
end
