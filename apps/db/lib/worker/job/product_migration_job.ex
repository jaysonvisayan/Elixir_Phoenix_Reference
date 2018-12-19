defmodule Innerpeace.Db.Worker.Job.ProductMigrationJob do
  alias Innerpeace.{
    Db.Repo,
    Db.Base.Api.ProductContext,
    Db.Base.UserContext,
    Worker.Job.NotificationJob,
    Worker.Job.CreateProductJob
  }
  alias Innerpeace.Db.Schemas.{
    Migration,
    MigrationNotification,
  }
  alias Ecto.Changeset

  def perform(params, user_id, products_count) do

    user =
      user_id
      |> UserContext.get_user!

    Exq
    |> Exq.enqueue(
      "product_migration_job",
      "Innerpeace.Db.Worker.Job.CreateProductJob",
      [user.id, params, params["migration_id"]]
    )

    Exq
    |> Exq.enqueue_in(
      "notification_job", 30,
      "Innerpeace.Db.Worker.Job.NotificationJob",
      [params["migration_id"], products_count]
    )

  end

  defp start_of_migration(user_id) do
    %Migration{}
    |> Migration.changeset(%{user_id: user_id, is_done: false, module: "Product"})
    |> Repo.insert()
  end

end
