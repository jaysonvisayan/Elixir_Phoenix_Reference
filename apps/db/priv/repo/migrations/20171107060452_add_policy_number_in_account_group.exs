defmodule Innerpeace.Db.Repo.Migrations.AddPolicyNumberInAccountGroup do
  use Ecto.Migration

  def change do
    alter table(:account_groups) do
      add :policy_no, :string
    end
  end
end
