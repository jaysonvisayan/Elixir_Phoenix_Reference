defmodule Innerpeace.Db.Repo.Migrations.AddReplicatedInAccountGroup do
  use Ecto.Migration

  def change do
    alter table(:account_groups) do
      add :replicated, :string
    end
  end
end
