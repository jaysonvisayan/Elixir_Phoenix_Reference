defmodule Innerpeace.Db.Worker.Job.NotificationJob do
  @moduledoc """
  A recursive job checker for validating queues that has been ongoing
  then go to ${notifier()}

  if the job checker is finished || job checker is failing
  notifier would be: {
    - user.email
    - mattermost webhook
    - extract_{Benefit, Product, Account, Member}_results (for finished and failing only)
  }

  """
  import Ecto.{Query, Changeset}, warn: false
  alias Innerpeace.{
    Db.Repo,
    Db.Schemas.Migration,
    Db.Schemas.MigrationNotification,
    Db.Schemas.MigrationExtractedResultLog,
    Db.Base.Api.UtilityContext,
  }

  def perform(module, endpoint, migration_id, count, previous_log_count) do
    migration =
      Migration
      |> Repo.get(migration_id)
      |> Repo.preload([:migration_notifications, :user])

    check_job_status(module, endpoint, migration, count, previous_log_count)
  end

  def check_job_status(module, endpoint, migration, count, previous_log_count) do
    mn = migration.migration_notifications
    cond do
      ## alc =  previous_log_count vs mn = migration.migration_notifications count
      is_equal_alc_vs_mn?(mn,  previous_log_count) == true and check_migrated_members(mn, count) == false ->
          job_interrupted(migration)
          api_send_email(migration)
          notify_devops_channel(endpoint, migration, "Failed Job")
          extract_result(module, migration, endpoint)

      is_equal_alc_vs_mn?(mn, previous_log_count) == false and check_migrated_members(mn, count) == false ->
          job_ongoing(module, endpoint, migration, count)
          api_send_email(migration)
          notify_devops_channel(endpoint, migration, "Ongoing Job")

      check_migrated_members(mn, count) == true ->
          job_done(migration)
          api_send_email(migration)
          notify_devops_channel(endpoint, migration, "Job Finished!")
          extract_result(module, migration, endpoint)
      true ->
          job_done(migration)
          api_send_email(migration)
          notify_devops_channel(endpoint, migration, "Job Finished")
    end
  end

  def check_job_status(job_param, "MIX_ENV=test") do
    mn = job_param.migration.migration_notifications
    cond do
      is_equal_alc_vs_mn?(mn,  job_param.previous_log_count) == true and
        check_migrated_members(mn, job_param.count) == false ->
          "Background Worker is Failing"
      is_equal_alc_vs_mn?(mn, job_param.previous_log_count) == false and
        check_migrated_members(mn, job_param.count) == false ->
          "Background Worker is Ongoing"
      check_migrated_members(mn, job_param.count) == true ->
        "Job Done"
      true -> "Job Done!"
    end
  end

  defp check_migrated_members(migration_notifications, count), do:
    if count == migration_notifications |> Enum.count(), do: true, else: false
  defp is_equal_alc_vs_mn?(migration_notifications, previous_log_count), do:
    if previous_log_count == migration_notifications |> Enum.count(), do: true, else: false

  defp job_done(migration) do
    fetch_false =
      MigrationNotification
      |> where([mn], mn.migration_id == ^migration.id and mn.is_fetch == false)
      |> select([mn], mn.id)
      |> Repo.all()

    MigrationNotification
    |> where([mn], mn.id in ^fetch_false)
    |> Repo.update_all(set: [is_fetch: true])

    migration
    |> Migration.changeset(%{is_done: true})
    |> Repo.update()
  end

  defp job_ongoing(module, endpoint, migration, count) do
    fetch_false =
      MigrationNotification
      |> where([mn], mn.migration_id == ^migration.id and mn.is_fetch == false)
      |> Repo.all()
      |> Enum.map(&(&1.id))

    MigrationNotification
    |> where([mn], mn.id in ^fetch_false)
    |> Repo.update_all(set: [is_fetch: true])

    Exq
    |> Exq.enqueue_in(
      "notification_job", 60,
      "Innerpeace.Db.Worker.Job.NotificationJob",
      [module, endpoint, migration.id, count, current_job_count(migration)])
  end

  defp current_job_count(migration) do
    MigrationNotification
    |> where([mn], mn.migration_id == ^migration.id)
    |> Repo.all()
    |> Enum.count()
  end

  defp job_interrupted(migration) do
    fetch_false =
      MigrationNotification
      |> where([mn], mn.migration_id == ^migration.id and mn.is_fetch == false)
      |> Repo.all()
      |> Enum.map(&(&1.id))

    MigrationNotification
    |> where([mn], mn.id in ^fetch_false)
    |> Repo.update_all(set: [is_fetch: true])
  end

  #### cant reuse migration_view, worker doesnt have an access in payorlink
  defp filter_newly_md_count(migration), do:
    migration.migration_notifications
    |> Enum.filter(&(&1.result == "Newly Migrated Data"))
    |> Enum.count()

  defp filter_already_md_count(migration), do:
    migration.migration_notifications
    |> Enum.filter(&(&1.result == "Already Migrated Data"))
    |> Enum.count()

  defp filter_failed_md_count(migration), do:
    migration.migration_notifications
    |> Enum.filter(&(&1.result == "Failed Migrated Data"))
    |> Enum.count()

  defp filter_newly(migration_notifications), do:
    migration_notifications |> Enum.filter(&(&1.result == "Newly Migrated Data"))

  defp filter_already(migration_notifications), do:
    migration_notifications |> Enum.filter(&(&1.result == "Already Migrated Data"))

  defp filter_failed(migration_notifications), do:
    migration_notifications |> Enum.filter(&(&1.result == "Failed Migrated Data"))

  def notify_devops_channel(endpoint, migration, status) do
    total_count = (filter_newly_md_count(migration) +
      filter_failed_md_count(migration) +
        filter_already_md_count(migration)
    )
    newly = filter_newly_md_count(migration)
    already = filter_already_md_count(migration)
    failed = filter_failed_md_count(migration)
    {:ok, now} =
      "Asia/Manila"
      |> Timex.now()
      |> Timex.format("{0M}-{0D}-{YYYY} {0h12}:{0m}{AM}")

    mattermost_migration_hook = "https://mattermost.medilink.com.ph/hooks/4fot3fzfzigg3ya3iitq68yqia"
    headers = [{"Content-type", "application/json"}]
    body = %{
        text: "#### Migration results asof #{now} \n #### Status: #{status} \n #### Migration_id: #{migration.id} \n #### Module: #{migration.module} \n
|     Details           |     Result                                                                          |
|:----------------------|:------------------------------------------------------------------------------------|
| Data Sent             |   #{migration.count}                                                                |
| Processed             |   #{total_count}                                                                    |
| Newly Migrated Data   |   #{newly}                                                                          |
| Already Migrated Data |   #{already}                                                                        |
| Failed Migrated Data  |   #{failed}                                                                         |
| JSON Link             |   #{endpoint}/migration/#{migration.id}/json/result                                 |
| WebPage Link          |   #{endpoint}/migration/#{migration.id}/results                                     |
        "
    }
    |> Poison.encode!()

    with :prod <- Application.get_env(:db, :env),
         {:ok, response} <- HTTPoison.post(mattermost_migration_hook, body, headers)
    do
      "dev hook sent"
    else
      :test ->
        "dev hook sent"
      :dev ->
        "dev hook sent"
      _ ->
        {:mattermost_error, "Mattermost Error, wrong link or wrong body parameter"}
    end
  end

  def api_send_email(migration) do
    with {:ok, token, address} <- UtilityContext.payorlinkv2_sign_in_with_address_return(),
         head <- [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}],
         url <- "#{address}/api/v1/email/migration/details",
         body <- Poison.encode!(%{migration_id: migration.id}),
         {:ok, response} <- HTTPoison.post(url, body, head, [])
    do
      response
    else
      {:error, response} -> {:error, response}
      {:error, response} -> {:unable_to_login, response}
      _ -> {:unable_to_login, "Error occurs when attempting to login in Payorlink"}
    end
  end

  defp extract_result(module, migration, endpoint) when module == "Member",
    do: submit_extracted_result(migration, "Extract#{module}Result", module, endpoint)
  defp extract_result(module, migration, endpoint) when module == "Benefit",
    do: submit_extracted_result(migration, "Extract#{module}Result", module, endpoint)
  defp extract_result(module, migration, endpoint) when module == "Product",
    do: submit_extracted_result(migration, "Extract#{module}Result", module, endpoint)
  defp extract_result(module, migration, endpoint) when module == "Account",
    do: submit_extracted_result(migration, "Extract#{module}Result", module, endpoint)

  defp submit_extracted_result(migration, url_module, module, endpoint) do
    with {:ok, token, address} <- UtilityContext.get_payorlink_one_token(),
         head <- [{"Content-type", "application/json"}, {"authorization", "Bearer #{token}"}],
         url <- "#{address}/payorAPI/v5/api/#{url_module}",
         body <- encoded_details(
           migration.migration_notifications,
           [],
           module,
           migration.id,
           endpoint
         ),
         {:ok, response} <- HTTPoison.post(url, body, head, []),
         200 <- response.status_code
    do
      extracted_result_logs(%{
        module: module,
        status_code: response.status_code |> Integer.to_string() ,
        migration_id: migration.id,
        remarks: "Success"
      })
    else
      401 ->
        extracted_result_logs(%{
          module: module, status_code: "401", migration_id: migration.id, remarks: "Error 401"
        })

      {:error, response} ->
        extracted_result_logs(%{
          module: module,
          status_code: response.status_code |> Integer.to_string(),
          migration_id: migration.id,
          remarks: response.body
        })

      {:error, response} ->
        extracted_result_logs(%{
          module: module,
          status_code: response.status_code |> Integer.to_string(),
          migration_id: migration.id,
          remarks: "Unable to login"
        })

      _ ->
        extracted_result_logs(%{
          module: module, status_code: "500", migration_id: migration.id,
          remarks: "An error has occured"
        })
    end
  end

  defp extracted_result_logs(%{module: w, status_code: x, migration_id: y, remarks: z} = params), do: insert_logs(params)
  defp insert_logs(params) do
    %MigrationExtractedResultLog{}
    |> MigrationExtractedResultLog.changeset(params)
    |> Repo.insert()
  end

  defp module_key(module, encoded_body, migration_id, endpoint),
    do: %{module => encoded_body, "url" => "#{endpoint}/migration/#{migration_id}/results"} |> Poison.encode!()
  defp encoded_details([], result, module, migration_id, endpoint), do: module_key(module, result, migration_id, endpoint)
  defp encoded_details([head | tails], result, module, migration_id, endpoint) when module == "Benefit" do
   result =
     result ++ [%{
       result: head.result,
       benefit_code: Enum.at(String.split(head.details, ", "), 0),
       benefit_details: Enum.at(String.split(head.details, ", "), 1),
       migration_details: Enum.at(String.split(head.details, ", "), 2)
     }]

   encoded_details(tails, result, module, migration_id, endpoint)
  end
  defp encoded_details([head | tails], result, module, migration_id, endpoint) when module == "Product" do
   result =
     result ++ [%{
       result: head.result,
       plan_code: Enum.at(String.split(head.details, ", "), 0),
       plan_details: Enum.at(String.split(head.details, ", "), 1),
       migration_details: Enum.at(String.split(head.details, ", "), 2)
     }]

    encoded_details(tails, result, module, migration_id, endpoint)
  end
  defp encoded_details([head | tails], result, module, migration_id, endpoint) when module == "Account" do
   result =
     result ++ [%{
       result: head.result,
       account_code: Enum.at(String.split(head.details, "| "), 0),
       account_details: Enum.at(String.split(head.details, "| "), 1),
       migration_details: Enum.at(String.split(head.details, "| "), 2)
     }]

   encoded_details(tails, result, module, migration_id, endpoint)
  end
  defp encoded_details([head | tails], result, module, migration_id, endpoint) when module == "Member" do
   result =
     result ++ [%{
       result: head.result,
       account_code: Enum.at(String.split(head.details, ", "), 0),
       member_details: Enum.at(String.split(head.details, ", "), 1),
       migration_details: head.migration_details,
     }]

   encoded_details(tails, result, module, migration_id, endpoint)
  end

end
