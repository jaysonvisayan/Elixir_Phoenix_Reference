defmodule Innerpeace.Db.Repo.Migrations.AddLoeNoInAuthorizationTable do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      add :loe_number, :string
    end
  end
end
