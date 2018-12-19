defmodule Innerpeace.Db.Repo.Migrations.AddMemberPolicyNo do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add :policy_no, :string
    end
  end

end
