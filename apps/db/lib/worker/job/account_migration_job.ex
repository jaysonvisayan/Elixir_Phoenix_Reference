defmodule Innerpeace.Db.Worker.Job.AccountMigrationJob do
  alias Innerpeace.{
    Db.Repo,
    Db.Base.Api.AccountContext,
    Db.Base.UserContext,
    Worker.Job.NotificationJob,
    Worker.Job.CreateAccountJob
  }
  alias Innerpeace.Db.Schemas.{
    Migration,
    MigrationNotification,
  }
  alias Ecto.Changeset

  def perform(module, url_endpoint, params, user_id, accounts_count) do

    user =
      user_id
      |> UserContext.get_user!

    params["accounts"]
    |> Enum.map(&(
      Exq
      |> Exq.enqueue(
        "account_migration_job",
        "Innerpeace.Db.Worker.Job.CreateAccountJob",
        [user.id, &1, params["migration_id"]]
      )
    ))

    notifier(module, url_endpoint, params, accounts_count)
  end

  def notifier(module, url_endpoint, params, accounts_count) when accounts_count == 0, do: nil
  def notifier(module, url_endpoint, params, accounts_count) when accounts_count <= 5  do
    Exq
    |> Exq.enqueue_in(
      "notification_job", 3,
      "Innerpeace.Db.Worker.Job.NotificationJob",
      [module, url_endpoint, params["migration_id"], accounts_count, 0]
    )
  end
  def notifier(module, url_endpoint, params, accounts_count) do
    # one_hour = 3600# sec
    Exq
    |> Exq.enqueue_in(
      "notification_job", 60,
      "Innerpeace.Db.Worker.Job.NotificationJob",
      [module, url_endpoint, params["migration_id"], accounts_count, 0]
    )
  end

  defp start_of_migration(user_id) do
    %Migration{}
    |> Migration.changeset(%{user_id: user_id, is_done: false, module: "Account"})
    |> Repo.insert()
  end

end
