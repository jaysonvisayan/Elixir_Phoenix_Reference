defmodule Innerpeace.Db.Repo.Migrations.ModifyChiefAuthorizationChiefComplaint do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      modify :chief_complaint, :text
      modify :internal_remarks, :text
    end
  end
end
