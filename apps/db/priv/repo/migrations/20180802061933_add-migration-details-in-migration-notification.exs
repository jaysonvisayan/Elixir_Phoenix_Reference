defmodule :"Elixir.Innerpeace.Db.Repo.Migrations.Add-migration-details-in-migration-notification" do
  use Ecto.Migration

  def change do
    alter table(:migration_notifications) do
      add :migration_details, :string
    end
  end
end
