defmodule Innerpeace.Db.Repo.Migrations.AddStepToAuthorization do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      add :step, :integer
    end
  end
end
