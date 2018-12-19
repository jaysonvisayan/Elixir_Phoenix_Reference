defmodule Innerpeace.Db.Worker.Job.MemberExistingBatchMigrationJob do
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
        "create_member_job",
        "Innerpeace.Db.Worker.Job.CreateMemberExistingJob",
        [Map.put(&1, "version", params["version"]), params["migration_id"]]
      )
    ))

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

  defp insert_migration_details(migration_id, params) do
    %MigrationNotification{}
    |> MigrationNotification.changeset(
      %{
        is_success: params["is_success"],
        details: "#{params["card_no"]}: #{params["first_name"]} #{params["last_name"]}: #{params["details"]}" ,
        is_fetch: false,
        migration_id: migration_id
      }
    )
    |> Repo.insert()
  end

end
