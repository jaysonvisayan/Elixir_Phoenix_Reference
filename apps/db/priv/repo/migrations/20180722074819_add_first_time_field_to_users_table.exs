defmodule Innerpeace.Db.Repo.Migrations.AddFirstTimeFieldToUsersTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :first_time, :boolean, default: true
    end
  end

end
