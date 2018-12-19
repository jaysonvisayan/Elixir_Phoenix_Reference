defmodule Innerpeace.Db.Repo.Migrations.AddTemporaryPasswordToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :temporary_password, :string
    end
  end
end
