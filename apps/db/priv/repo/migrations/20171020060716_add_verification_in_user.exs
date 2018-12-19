defmodule Innerpeace.Db.Repo.Migrations.AddVerificationInUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :verification, :boolean
    end
  end
end
