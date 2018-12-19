defmodule Innerpeace.Db.Worker.Job.ProductBatchMigrationJob do
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

  def perform(module, url_endpoint, params, user_id, products_count) do

    user =
      user_id
      |> UserContext.get_user!

    params["products"]
    |> Enum.map(&(
      Exq
      |> Exq.enqueue(
        "product_migration_job",
        "Innerpeace.Db.Worker.Job.CreateProductJob",
        [user.id, &1, params["migration_id"]]
      )
    ))

    notifier(module, url_endpoint, params, products_count)

  end

  def notifier(module, url_endpoint, params, products_count) when products_count == 0, do: nil
  def notifier(module, url_endpoint, params, products_count) when products_count <= 5  do
    Exq
    |> Exq.enqueue_in(
      "notification_job", 3,
      "Innerpeace.Db.Worker.Job.NotificationJob",
      [module, url_endpoint, params["migration_id"], products_count, 0]
    )
  end
  def notifier(module, url_endpoint, params, products_count) do
    # one_hour = 3600# sec
    Exq
    |> Exq.enqueue_in(
      "notification_job", 60,
      "Innerpeace.Db.Worker.Job.NotificationJob",
      [module, url_endpoint, params["migration_id"], products_count, 0]
    )
  end

  defp start_of_migration(user_id) do
    %Migration{}
    |> Migration.changeset(%{user_id: user_id, is_done: false, module: "Product"})
    |> Repo.insert()
  end

end
