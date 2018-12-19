defmodule Innerpeace.Db.Repo.Migrations.AddIsArchivedInMemberProduct do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:member_products) do
      add :is_archived, :boolean, default: false
    end
  end
end
