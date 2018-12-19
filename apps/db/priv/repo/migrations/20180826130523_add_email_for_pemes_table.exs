defmodule Innerpeace.Db.Repo.Migrations.AddEmailForPemesTable do
  use Ecto.Migration

  def change do
    alter table(:pemes) do
    add :email_address, :string
    end
  end
end
