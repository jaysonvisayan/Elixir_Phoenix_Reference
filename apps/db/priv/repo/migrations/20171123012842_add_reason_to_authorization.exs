defmodule Innerpeace.Db.Repo.Migrations.AddReasonToAuthorization do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      add :reason, :string
    end
  end
end
