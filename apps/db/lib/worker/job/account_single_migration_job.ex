defmodule Innerpeace.Db.Worker.Job.AccountSingleMigrationJob do
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

  def perform(params, user_id, accounts_count) do
    user =
      user_id
      |> UserContext.get_user!

    Exq
    |> Exq.enqueue(
      "account_single_migration_job",
      "Innerpeace.Db.Worker.Job.CreateAccountJob",
      [user.id, params["params"], params["migration_id"]]
    )
    # Exq
    # |> Exq.enqueue_in(
    #   "notification_job", 30,
    #   "Innerpeace.Db.Worker.Job.NotificationJob",
    #   [params["migration_id"], accounts_count]
    # )
  end

  defp start_of_migration(user_id) do
    %Migration{}
    |> Migration.changeset(%{user_id: user_id, is_done: false, module: "Account"})
    |> Repo.insert()
  end

end

