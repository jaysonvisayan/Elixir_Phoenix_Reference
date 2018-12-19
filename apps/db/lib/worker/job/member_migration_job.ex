defmodule Innerpeace.Db.Worker.Job.MemberMigrationJob do
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

  def perform(params, user_id, members_count) do
    user =
      user_id
      |> UserContext.get_user!

      Exq
      |> Exq.enqueue(
        "create_member_job",
        "Innerpeace.Db.Worker.Job.CreateMemberJob",
        [params, params["migration_id"]]
      )

    # one_hour = 3600 # sec
    Exq
    |> Exq.enqueue_in(
      "notification_job", 30,
      "Innerpeace.Db.Worker.Job.NotificationJob",
      [params["migration_id"], members_count]
    )
  end

  defp start_of_migration(user_id) do
    # Timex.now("Asia/Manila")
    %Migration{}
    |> Migration.changeset(%{user_id: user_id, is_done: false, module: "Member"})
    |> Repo.insert()
  end

end
