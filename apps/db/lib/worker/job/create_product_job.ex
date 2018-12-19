defmodule Innerpeace.Db.Worker.Job.CreateProductJob do
  alias WorkerWeb.ErrorHelpers
  alias Innerpeace.{
    Db.Repo,
    Db.Base.Api.ProductContext,
    Db.Base.UserContext,
    Worker.Job.NotificationJob,
    Worker.Job.ProductMigrationJob
  }
  alias Innerpeace.Db.Schemas.{
    Migration,
    MigrationNotification,
  }

  alias Ecto.Changeset
  alias Innerpeace.Db.Base.Api.UtilityContext

  def perform(user_id, product_params, migration_id) do
    migration =
      Migration
      |> Repo.get(migration_id)

    product_params
    |> create_product(user_id, migration)

  end

  def create_product(product_params, user_id, migration) do
    migration_id = product_params["migration_id"]
    product_params =
      product_params
      |> Map.delete("migration_id")

    user = Innerpeace.Db.Base.UserContext.get_user(user_id)

    with {:ok, product} <- ProductContext.validate_insert(user, product_params) do
      product_params =
        product_params
        |> Map.put("is_success", true)
        |> Map.put("result", "Newly Migrated Data")
        |> Map.put("details", "")
        |> Map.put("migration_id", migration_id)

      migration
      |> insert_migration_details(product_params)

    else
      {:error, changeset} ->
        errors = transform_errors(translate_errors(changeset))

        cond do
          Enum.count(errors) == 1 && Enum.member?(errors, "code: Product Code already exist!") ->
            product_params =
              product_params
              |> Map.put("is_success", false)
              |> Map.put("result", "Already Migrated Data")
              |> Map.put("details", errors)
              |> Map.put("migration_id", migration_id)

              migration
              |> insert_migration_details(product_params)

          Enum.count(errors) != 1 && Enum.member?(errors, "code: Product Code already exist!") ->
            errors =
              errors
              |> Enum.join(", ")

            product_params =
              product_params
              |> Map.put("is_success", false)
              |> Map.put("result", "Failed Migrated Data")
              |> Map.put("details", errors)
              |> Map.put("migration_id", migration_id)

            migration
            |> insert_migration_details(product_params)

            true ->
            errors =
              errors
              |> Enum.join(", ")

              product_params =
                product_params
                |> Map.put("is_success", false)
                |> Map.put("result", "Failed Migrated Data")
                |> Map.put("details", errors)
                # |> Map.put("details", test_error)
                |> Map.put("migration_id", migration_id)

                migration
                |> insert_migration_details(product_params)

        end
    end

   rescue
     _ ->
        product_params =
          product_params
          |> Map.put("is_success", false)
          |> Map.put("result", "Failed Migrated Data")
          |> Map.put("details", "Error In Server")

      migration
      |> insert_migration_details(product_params)
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
          details: "#{params["code"]}; #{params["name"]}; #{params[""]}: succesfully migrated.",
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
          details: "#{params["code"]}; #{params["name"]}; #{params[""]} #{params["details"]}",
          is_fetch: false,
          migration_id: struct.id
        }
      )
      |> Repo.insert()

    end
  end

  defp transform_errors(details) do
    details
    |> Enum.map(fn({x, y}) -> "#{x}: #{List.first(y)}" end)
  end

  defp transform_error(details) do
    test = Enum.map(details, fn({x, y}) ->
      {a, b} = y
      a
    end)
  end

end
