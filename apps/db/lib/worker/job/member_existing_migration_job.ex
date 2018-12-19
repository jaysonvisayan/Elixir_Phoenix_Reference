defmodule Innerpeace.Db.Worker.Job.MemberExistingMigrationJob do
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

    # filter_member(params["members"], params["migration_id"])

      Exq
      |> Exq.enqueue(
        "create_member_job",
        "Innerpeace.Db.Worker.Job.CreateMemberExistingJob",
        [params, params["migration_id"]]
      )

    # one_hour = 3600# sec
    Exq
    |> Exq.enqueue_in(
      "notification_job", 30,
      "Innerpeace.Db.Worker.Job.NotificationJob",
      [params["migration_id"], members_count]
    )
  end

  # def filter_member(members, migration_id) do
  #     members
  #     |> Enum.map(fn(p) ->
  #         members  = members -- [p]
  #       if Enum.find_value(members, fn(member) ->
  #          [member["account_code"], member["employee_no"]] == [p["account_code"], p["employee_no"]]
  #       end) do
  #         p =
  #           p
  #           |> Map.put("is_success", false)
  #           |> Map.put("details", "Duplicate account code and employee no!")
  #         insert_migration_details(migration_id, p)
  #       else
  #         Exq
  #         |> Exq.enqueue(
  #           "create_member_existing_job",
  #           "Innerpeace.Db.Worker.Job.CreateMemberExistingJob",
  #           [p, migration_id]
  #           # max_retries: 5
  #         )
  #       end
  #     end)
  # end

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

  defp start_of_migration(user_id) do
    # Timex.now("Asia/Manila")
    %Migration{}
    |> Migration.changeset(%{user_id: user_id, is_done: false, module: "Member"})
    |> Repo.insert()
  end

end
