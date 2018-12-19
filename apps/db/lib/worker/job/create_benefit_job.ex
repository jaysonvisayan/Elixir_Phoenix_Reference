defmodule Innerpeace.Db.Worker.Job.CreateBenefitJob do
  alias WorkerWeb.ErrorHelpers
  alias Innerpeace.{
    Db.Repo,
    Db.Base.Api.BenefitContext,
    Db.Base.UserContext,
    Worker.Job.NotificationJob,
    Worker.Job.BenefitMigrationJob
  }
  alias Innerpeace.Db.Schemas.{
    Migration,
    MigrationNotification,
  }

  alias Ecto.Changeset
  alias Innerpeace.Db.Base.Api.UtilityContext

  def perform(user_id, benefit_params, migration_id) do
    migration =
      Migration
      |> Repo.get(migration_id)

    benefit_params
    |> create_benefit(user_id, migration)
  end

  def create_benefit(benefit_params, user_id, migration) do
    migration_id = benefit_params["migration_id"]
    benefit_params =
      benefit_params
      |> Map.delete("migration_id")

    with {:ok, benefit} <- BenefitContext.create_benefit(%{id: user_id}, benefit_params) do
      benefit_params =
        benefit_params
        |> Map.put("is_success", true)
        |> Map.put("result", "Newly Migrated Data")
        |> Map.put("details", "Success")

      migration
      |> insert_migration_details(benefit_params)

    else
      {:error, changeset} ->
        errors = String.split(changeset, ", ")
      c_error = Enum.map(errors, fn(x) ->
        x
      end)
    test_error =  Enum.join(c_error, ",")
        if Enum.count(errors) == 1 && Enum.member?(errors, "code already exists") do
          benefit_params =
            benefit_params
            |> Map.put("is_success", false)
            |> Map.put("result", "Already Migrated Data")
            |> Map.put("details", test_error)
            |> Map.put("migration_id", migration_id)

            migration
            |> insert_migration_details(benefit_params)

        else
          Enum.member?(errors, "code already exists")
          benefit_params =
            benefit_params
            |> Map.put("is_success", false)
            |> Map.put("result", "Failed Migrated Data")
            |> Map.put("details", test_error)
            |> Map.put("migration_id", migration_id)

            migration
            |> insert_migration_details(benefit_params)

        end

      _ ->
      benfit_params =
        benefit_params
        |> Map.put("is_success", false)
        |> Map.put("details", "Error In Server")
        |> Map.put("migration_id", migration_id)

    migration
    |> insert_migration_details(benefit_params)

    end

    rescue
    e in Ecto.ConstraintError ->
        benefit_params =
          benefit_params
          |> Map.put("is_success", false)
          |> Map.put("details", "Code Already Exists")

          migration
          |> insert_migration_details(benefit_params)


    e in DBConnection.ConnectionError ->
      benefit_params =
        benefit_params
        |> Map.put("is_success", false)
        |> Map.put("details", "Connection Error.")

    migration
    |> insert_migration_details(benefit_params)


    _ ->

      benfit_params =
        benefit_params
        |> Map.put("is_success", false)
        |> Map.put("details", "Error In Server")

      migration
      |> insert_migration_details(benefit_params)
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
          details: "#{params["code"]}, #{params["name"]}, #{params[""]}: succesfully migrated.",
          is_fetch: false,
          migration_id: struct.id
        }
      )
      |> Repo.insert()

    else
      %MigrationNotification{}
      |> MigrationNotification.changeset(
        %{
          is_success: params["is_success"],
          result: params["result"],
          details: "#{params["code"]}, #{params["name"]}, #{params[""]}: #{params["details"]}",
          is_fetch: false,
          migration_id: struct.id
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

  defp transform_error(details) do
    test = Enum.map(details, fn({x, y}) ->
      {a, b} = y
      a
    end)
  end
end
