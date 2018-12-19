defmodule Innerpeace.Db.Repo.Migrations.AlterAuthorizationsField do
  use Ecto.Migration

  def change do
  	alter table(:authorizations) do
      add :chief_complaint_others, :string
    end
  end
end
