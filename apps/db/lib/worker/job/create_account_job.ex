defmodule Innerpeace.Db.Worker.Job.CreateAccountJob do
  alias WorkerWeb.ErrorHelpers
  alias Innerpeace.{
    Db.Repo,
    Db.Base.Api.AccountContext,
    Db.Base.UserContext,
    Db.Base.Api.UtilityContext,
    Worker.Job.NotificationJob,
    Worker.Job.AccountMigrationJob
  }
  alias Innerpeace.Db.Schemas.{
    Migration,
    MigrationNotification,
  }

  alias Ecto.Changeset

  def perform(user_id, account_params, migration_id) do
    migration =
      Migration
      |> Repo.get(migration_id)

    account_params
    |> create_account(user_id, migration)

  end

  def create_account(account_params, user_id, migration) do
    with {:ok, account_group, account_product, approver} <- AccountContext.validate_insert(%{id: user_id}, account_params) do
      account_params =
        account_params
        |> Map.put("is_success", true)
        |> Map.put("result", "Newly Migrated Data")
        |> Map.put("details", "")

      migration
      |> insert_migration_details(account_params)

    else
      {:error, changeset} ->
        errors = transform_error(changeset.errors)
        cond do
          Enum.count(errors) == 1 && Enum.member?(errors, "Account Code already exists") ->
            account_params =
              account_params
              |> Map.put("is_success", false)
              |> Map.put("result", "Already Migrated Data")
              |> Map.put("details", translate_errors(changeset))

              migration
              |> insert_migration_details(account_params)

          Enum.count(errors) == 1 && Enum.member?(errors, "Account name is already exist!") ->
            account_params =
              account_params
              |> Map.put("is_success", false)
              |> Map.put("result", "Already Migrated Data")
              |> Map.put("details", translate_errors(changeset))

              migration
              |> insert_migration_details(account_params)

          Enum.count(errors) != 1 && Enum.member?(errors, "Account Code already exists") ->
            account_params =
              account_params
              |> Map.put("is_success", false)
              |> Map.put("result", "Failed Migrated Data")
              |> Map.put("details", translate_errors(changeset))

              migration
              |> insert_migration_details(account_params)

          true ->
            account_params =
              account_params
              |> Map.put("is_success", false)
              |> Map.put("result", "Failed Migrated Data")
              |> Map.put("details", translate_errors(changeset))

              migration
              |> insert_migration_details(account_params)
        end
    end

   # rescue
   #  _ ->

   #    account_params =
   #      account_params
   #      |> Map.put("is_success", false)
   #      |> Map.put("result", "Failed Migrated Data")
   #      |> Map.put("details", "Error In Server")

   #    migration
   #    |> insert_migration_details(account_params)
  end

  defp translate_errors(changeset) do
    Changeset.traverse_errors(
      changeset,
      &ErrorHelpers.translate_error/1
    )
  end

  defp insert_migration_details(struct, params) do
    if params["is_success"] do
      {:ok, migration_notification} =
       %MigrationNotification{}
        |> MigrationNotification.changeset(
          %{
            is_success: params["is_success"],
            result: params["result"],
            details: "#{params["code"]}| #{params["name"]}| #{params[""]}: successfully migrated.",
            is_fetch: false,
            # migration_details: "succesfully migrated",
            migration_id: struct.id
          }
        )
        |> Repo.insert()

      sap_params = %{
        "code" => "#{params["code"]}",
        "status_code" => "200",
        "message" => "SUCCESSFULLY MIGRATED",
        "module" => "Account",
        "migration_notification_id" => migration_notification.id
      }

      UtilityContext.sap_update_status(sap_params)

    else
      {:ok, migration_notification} =
        %MigrationNotification{}
        |> MigrationNotification.changeset(
          %{
            is_success: params["is_success"],
            result: params["result"],
            details: "#{params["code"]}| #{params["name"]}| #{params[""]}: #{transform_errors(params["details"])}",
            is_fetch: false,
            migration_id: struct.id
          }
        )
        |> Repo.insert()

      sap_params = %{
        "code" => "#{params["code"]}",
        "status_code" => "200",
        "message" => "ERROR IN MIGRATION",
        "module" => "Account",
        "migration_notification_id" => migration_notification.id
      }

      UtilityContext.sap_update_status(sap_params)

    end
  end

  defp transform_errors(details) do
    details
    |> Enum.map(fn({x, y}) -> "#{x} #{List.first(y)}" end)
    |> Enum.join(", ")
  end

  defp transform_error(details) do
    test = Enum.map(details, fn({x, y}) ->
      {a, b} = y
      a
    end)
  end

end
