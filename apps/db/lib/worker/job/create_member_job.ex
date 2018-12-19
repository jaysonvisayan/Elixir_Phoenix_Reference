defmodule Innerpeace.Db.Worker.Job.CreateMemberJob do
  alias WorkerWeb.ErrorHelpers
  alias Innerpeace.{
    Db.Repo,
    Db.Base.Api.MemberContext,
    Db.Base.Api.UtilityContext,
    Db.Base.UserContext,
    Worker.Job.NotificationJob,
    Worker.Job.MemberMigrationJob
  }
  alias Innerpeace.Db.Schemas.{
    Migration,
    MigrationNotification,
  }

  alias Ecto.Changeset

  def perform(member_params, migration_id) do
    migration =
      Migration
      |> Repo.get(migration_id)

    member_params
    |> create_member(migration)

  end

  def create_member(member_params, migration) do
    migration_id = member_params["migration_id"]

    member_params =
      member_params
      |> Map.delete("migration_id")

    with {:ok, member} <- MemberContext.create(member_params) do
      member_params =
        member_params
        # |> Map.put("json_params", member_params)
        |> Map.put("is_success", true)
        |> Map.put("result", "Newly Migrated Data")
        |> Map.put("details", "Success")
        |> Map.put("migration_id", migration_id)

      migration
      |> insert_migration_details(member_params)

    else
      {:error, changeset} ->
        member_params =
          member_params
          # |> Map.put("json_params", member_params)
          |> Map.put("is_success", false)
          |> Map.put("result", "Failed Migrated Data")
          |> Map.put("details", UtilityContext.changeset_errors_to_string(changeset.errors))
          |> Map.put("migration_id", migration_id)

        migration
        |> insert_migration_details(member_params)

      _ ->
        member_params =
          member_params
          # |> Map.put("json_params", member_params)
          |> Map.put("is_success", false)
          |> Map.put("result", "Failed Migrated Data")
          |> Map.put("details", "ERROR")
          |> Map.put("migration_id", migration_id)

          migration
          |> insert_migration_details(member_params)

    end

    rescue
    e in Ecto.ConstraintError ->
      member_params =
        member_params
        |> Map.put("json_params", member_params)
        |> Map.put("is_success", false)
        |> Map.put("result", "Failed Migrated Data")
        # |> Map.put("details", "This employee no cannot be enrolled because it is used by another member.")
        |> Map.put("details", "already exists within the account")

        migration
        |> insert_migration_details(member_params)

        e in DBConnection.ConnectionError ->
          member_params =
            member_params
            |> Map.put("json_params", member_params)
            |> Map.put("is_success", false)
            |> Map.put("result", "Failed Migrated Data")
            |> Map.put("details", "Error In DB Connection")

          migration
          |> insert_migration_details(member_params)

          _ ->
            member_params =
              member_params
              |> Map.put("json_params", member_params)
              |> Map.put("is_success", false)
              |> Map.put("details", "Error in server or data")

            migration
            |> insert_migration_details(member_params)
  end

  defp translate_errors(changeset) do
    Changeset.traverse_errors(
      changeset,
      &ErrorHelpers.translate_error/1
    )
  end

  defp insert_migration_details(struct, params) do
    if params["is_success"] do
      %MigrationNotification{}
      |> MigrationNotification.changeset(
        %{
          is_success: params["is_success"],
          result: params["result"],
          details: "#{params["account_code"]}, #{params["card_no"]}: #{params["first_name"]} #{params["last_name"]}",
          is_fetch: false,
          migration_details: "successfully migrated.",
          migration_id: struct.id,
          json_params: params["json_params"]
        }
      )
      |> Repo.insert()

    else
      %MigrationNotification{}
      |> MigrationNotification.changeset(
        %{
          is_success: params["is_success"],
          result: params["result"],
          details: "#{params["account_code"]}, #{params["first_name"]} #{params["last_name"]}",
          is_fetch: false,
          migration_details: "#{params["details"]}",
          migration_id: struct.id,
          json_params: params["json_params"]
        }
      )
      |> Repo.insert()

    end
  end

  defp transform_errors(details) do
    details
    |> Enum.map(fn({x, y}) -> "#{x} #{List.first(y)}" end)
    |> Enum.join(", ")
  end
end
