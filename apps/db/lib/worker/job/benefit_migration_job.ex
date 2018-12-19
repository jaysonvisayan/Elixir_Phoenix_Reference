defmodule Innerpeace.Db.Worker.Job.BenefitMigrationJob do
  @moduledoc false

  alias Innerpeace.{
    Db.Repo,
    Db.Base.Api.BenefitContext,
    Db.Base.UserContext,
    Worker.Job.NotificationJob,
    Worker.Job.CreateBenefitJob
  }
  alias Innerpeace.Db.Schemas.{
    Migration,
    MigrationNotification,
  }
  alias Ecto.Changeset

  def perform(params, user_id, benefits_count) do
    user =
      user_id
      |> UserContext.get_user!

      Exq
      |> Exq.enqueue(
        "benefit_migration_job",
        "Innerpeace.Db.Worker.Job.CreateBenefitJob",
        [user.id, params, params["migration_id"]]
      )

    Exq
    |> Exq.enqueue_in(
      "notification_job", 30,
      "Innerpeace.Db.Worker.Job.NotificationJob",
      [params["migration_id"], benefits_count]
    )

  end

  defp start_of_migration(user_id) do
    %Migration{}
    |> Migration.changeset(%{user_id: user_id, is_done: false, module: "Benefit"})
    |> Repo.insert()
  end
end
