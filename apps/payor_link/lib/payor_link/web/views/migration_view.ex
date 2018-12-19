defmodule Innerpeace.PayorLink.Web.MigrationView do
  use Innerpeace.PayorLink.Web, :view


  def count_result(migration_notifications, boolean) do
    migration_notifications
    |> Enum.filter(&(&1.is_success == boolean))
    |> Enum.count()
  end

  def count_result(migration_notifications, migration, result, boolean, type) do
    cond do
      type == "newly" ->
        if migration.module != "Members" do
          migration_notifications
          |> Enum.filter(&(&1.result == result))
          |> Enum.count()
        else
          migration_notifications
          |> Enum.filter(&(&1.is_success == boolean))
          |> Enum.count()
        end
      type == "migrated" ->
        if migration.module != "Members"  do
          migration_notifications
          |> Enum.filter(&(&1.result == result))
          |> Enum.count()
        else
          result = Enum.map(migration_notifications, fn(x) ->
            splitted_details = String.split(x.details, ":")
            splitted_result = String.split(Enum.at(splitted_details, 1), ",")
            if Enum.count(splitted_result) > 1 do
              0
            else
              splitted_result =
                splitted_result
                |> Enum.filter(&(String.contains?(&1, "already exists")))
                |> List.flatten()
                |> List.delete(nil)
                |> Enum.count()
            end
          end)
          if List.first(result) == 0 do
            0
          else
            List.first(result)
          end
        end
        type == "failed" ->
          migration_notifications
          |> Enum.filter(&(&1.result == result))
          |> Enum.count()
       true ->
         "0"
    end
  end

  def render("results.json", %{results: results, count: count}) do
    if Enum.count(results) >= String.to_integer(count) and Enum.count(results) != 1 do
      get_completed_migration(results, count)
    else
      if Enum.count(results) == 1 do
        get_status_single_migration(results, count)
      else
        get_ongoing_migration(results, count)
      end
    end
  end

  def get_completed_migration(results, count) do
    %{
      status: "completed",
      succes_count:  get_success_count(results),
      failed_count: get_failed_count(results),
      failed_remarks: render_one(
       results,
       Innerpeace.PayorLink.Web.MigrationView,
       "code.json", as: :codes),
      total_count: get_success_count(results) + get_failed_count(results)
    }
  end

  def get_ongoing_migration(results, count) do
    %{
      status: "ongoing",
      succes_count:  get_success_count(results),
      failed_count: get_failed_count(results),
      failed_remarks: render_one(
        results,
        Innerpeace.PayorLink.Web.MigrationView,
        "code.json", as: :codes),
      total_count: get_success_count(results) + get_failed_count(results)
    }
  end

  def get_status_single_migration(results, count) do
    results =
      results
      |> List.first()

    if results.is_success do
      %{
        status: "success",
        succes_count:  get_success_count([results]),
        failed_count: get_failed_count([results]),
        failed_remarks: "",
        total_count: get_success_count([results]) + get_failed_count([results])
      }
    else
      %{
        status: "failed",
        succes_count:  get_success_count([results]),
        failed_count: get_failed_count([results]),
        failed_remarks: render_one(
          [results],
          Innerpeace.PayorLink.Web.MigrationView,
          "code.json", as: :codes),
        total_count: get_success_count([results]) + get_failed_count([results])
      }
    end
  end

  def render("code.json", %{codes: codes}) do
    test = Enum.map(codes, fn(x) ->
      if x.is_success == false do
        key = x.details
              |> String.split(": ")
              |> Enum.at(0)
        error_list = x.details
                     |> String.split(": ")
                     |> Enum.reject(&(&1 == key))

        # detail_splitted = String.split(x.details, ":")
        # detail_remarks = String.split(Enum.at(detail_splitted, 1), ",")
        if key == "" do
          %{
            "NOCODE": error_list
          }
        else
          %{
            # "#{Enum.at(detail_splitted, 0)}": detail_remarks
            "#{key}": "#{error_list}"
          }
        end
      end
    end)
    test =
      test
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
  end

  def get_failed_count(results) do
    failed = Enum.map(results, fn(x) ->
      if x.is_success == false do
        x
      end
    end)

    failed =
      failed
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
      |> Enum.count()
  end

  def get_success_count(results) do
    success = Enum.map(results, fn(x) ->
      if x.is_success do
        x
      end
    end)

    success =
      success
      |> List.flatten()
      |> Enum.uniq()
      |> List.delete(nil)
      |> Enum.count()
  end

  ################################ member existing batch response_v2 ##########################################
  def render("result_v2.json", %{migration: nil}), do: %{ message: "Failed to create migration" }
  def render("result_v2.json", %{migration: migration}) do
    %{
      data_sent: migration.count,
      newly_migrated_data: filter_newly_md_count(migration),
      already_migrated_data: filter_already_md_count(migration),
      failed_migrated_data: filter_failed_md_count(migration),
      processed: ( filter_newly_md_count(migration) + filter_failed_md_count(migration) + filter_already_md_count(migration) ),
      info: %{
        newly_migrated_data: render_many(migration.migration_notifications |> filter_newly(),
                 Innerpeace.PayorLink.Web.MigrationView,
                "migration_notification.json", as: :migration_notification),
        already_migrated_data: render_many(migration.migration_notifications |> filter_already(),
                 Innerpeace.PayorLink.Web.MigrationView,
                "migration_notification.json", as: :migration_notification),
        failed_migrated_data: render_many(migration.migration_notifications |> filter_failed(),
                 Innerpeace.PayorLink.Web.MigrationView,
                "migration_notification.json", as: :migration_notification)
      }
    }
  end

  def render("migration_notification.json", %{migration_notification: migration_notification}) do
    %{
      parameters: migration_notification.json_params,
      id: migration_notification.id,
      member_details: migration_notification.details,
      is_success: migration_notification.is_success,
      result: migration_notification.result,
      migration_details: migration_notification.migration_details
    }
  end

  defp filter_newly_md_count(migration), do:
    migration.migration_notifications
    |> Enum.filter(&( &1.result == "Newly Migrated Data" ))
    |> Enum.count()
  defp filter_already_md_count(migration), do:
    migration.migration_notifications
    |> Enum.filter(&( &1.result == "Already Migrated Data" ))
    |> Enum.count()
  defp filter_failed_md_count(migration), do:
    migration.migration_notifications
    |> Enum.filter(&( &1.result == "Failed Migrated Data" ))
    |> Enum.count()

  defp filter_newly(migration_notifications), do:
    migration_notifications |> Enum.filter(&( &1.result == "Newly Migrated Data" ))
  defp filter_already(migration_notifications), do:
    migration_notifications |> Enum.filter(&( &1.result == "Already Migrated Data" ))
  defp filter_failed(migration_notifications), do:
    migration_notifications |> Enum.filter(&( &1.result == "Failed Migrated Data" ))

  ################################ member existing batch response_v2 ##########################################

  def check_env(conn) do
    if Application.get_env(:payor_link, :env) == :prod do
      Atom.to_string(conn.scheme) <> "://" <> Innerpeace.PayorLink.Web.Endpoint.struct_url.host
    else
      Innerpeace.PayorLink.Web.Endpoint.url
    end
  end

end
