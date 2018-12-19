defmodule Innerpeace.PayorLink.Web.EmailView do
  use Innerpeace.PayorLink.Web, :view

  def invite_url(url, password_token) do
    test = url |> String.split(":") |> Enum.at(1)
    case Mix.env do
      :dev ->
        "/create?password_token=#{password_token}"
      :prod ->
        "http:#{test}/create?password_token=#{password_token}"
      :test ->
        "/create?password_token=#{password_token}"
      _ ->
        raise "Invalid ENV!"
    end
  end

  def count_result(migration_notifications, boolean) do
    migration_notifications
    |> Enum.filter(&(&1.is_success == boolean))
    |> Enum.count()
  end

  def filter_newly_md_count(migration), do:
    migration.migration_notifications
    |> Enum.filter(&( &1.result == "Newly Migrated Data" ))
    |> Enum.count()
  def filter_already_md_count(migration), do:
    migration.migration_notifications
    |> Enum.filter(&( &1.result == "Already Migrated Data" ))
    |> Enum.count()
  def filter_failed_md_count(migration), do:
    migration.migration_notifications
    |> Enum.filter(&( &1.result == "Failed Migrated Data" ))
    |> Enum.count()

  def filter_newly(migration_notifications), do:
    migration_notifications |> Enum.filter(&( &1.result == "Newly Migrated Data" ))
  def filter_already(migration_notifications), do:
    migration_notifications |> Enum.filter(&( &1.result == "Already Migrated Data" ))
  def filter_failed(migration_notifications), do:
    migration_notifications |> Enum.filter(&( &1.result == "Failed Migrated Data" ))

end
