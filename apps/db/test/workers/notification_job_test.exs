defmodule Innerpeace.Db.Worker.NotificationJobTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Worker.Job.NotificationJob
  alias Innerpeace.Db.Base.MigrationContext

  describe "mock test for notification job" do

    test "notification job, checks if worker is ongoing" do
      migration = insert(:migration, count: 10) |> Repo.preload([:migration_notifications, :user])
      generate_migration_notification_data(7, migration)
      updated_migration = MigrationContext.get_migration(migration.id)

      notification_param =
        %{module: "Member",
          endpoint: "sample_scheme_localhost",
          migration: updated_migration,
          count: migration.count,
          previous_log_count: 5}
      assert "Background Worker is Ongoing" == NotificationJob.check_job_status(notification_param, "MIX_ENV=test")
    end

    test "notification job, checks if worker is finished" do
      migration = insert(:migration, count: 10) |> Repo.preload([:migration_notifications, :user])
      generate_migration_notification_data(10, migration)
      updated_migration = MigrationContext.get_migration(migration.id)

      notification_param =
        %{module: "Member",
          endpoint: "sample_scheme_localhost",
          migration: updated_migration,
          count: migration.count,
          previous_log_count: 5}
      assert "Job Done" == NotificationJob.check_job_status(notification_param, "MIX_ENV=test")
    end

    test "notification job, checks if worker is failing" do
      migration = insert(:migration, count: 10) |> Repo.preload([:migration_notifications, :user])
      generate_migration_notification_data(2, migration)
      updated_migration = MigrationContext.get_migration(migration.id)

      notification_param =
        %{module: "Member",
          endpoint: "sample_scheme_localhost",
          migration: updated_migration,
          count: migration.count,
          previous_log_count: 2}
      assert "Background Worker is Failing" == NotificationJob.check_job_status(notification_param, "MIX_ENV=test")
    end

  end

  defp generate_migration_notification_data(count, migration) do
    1..count
    |> Enum.to_list()
    |> Enum.map(fn(_x) -> insert(:migration_notification, migration: migration) end)
  end

end
