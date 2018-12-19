defmodule Innerpeace.Db.Base.MigrationContext do
  @moduledoc """
  """
  import Ecto.{Query}, warn: false
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    Migration,
    MigrationNotification
  }
  alias Ecto.Changeset

  def get_migration(id) do
    Migration
    |> Repo.get(id)
    |> Repo.preload([:user, :migration_notifications])
  end

  def get_migration_notification(migration) do
    MigrationNotification
    |> where([mn], mn.migration_id == ^migration.id)
    |> Repo.all()
  end

  def start_of_migration(user_id, count) do
    # Timex.now("Asia/Manila")
    %Migration{}
    |> Migration.changeset(%{user_id: user_id, is_done: false, module: "Member", count: count})
    |> Repo.insert()
  end

  def start_post(user_id, module) do
    %Migration{}
    |> Migration.changeset(%{user_id: user_id, is_done: false, module: module})
    |> Repo.insert()
  end

  def csv_downloads(params) do
    param = params["search_value"]
    query = (
      from m in MigrationNotification,
      where: ilike(m.details, ^("%#{param}%")) or ilike(fragment("?::text", m.is_success), ^("%#{param}%")),
      group_by: m.is_success,
      group_by: m.details,
      select: ([
        fragment("ROW_NUMBER() OVER()"),
        m.is_success,
        m.details
      ])
    )
    query = Repo.all(query)
  end

end
