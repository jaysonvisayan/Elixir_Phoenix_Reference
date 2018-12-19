defmodule Innerpeace.Db.Repo.Migrations.AddIdsToPractitionerAccount do
  use Ecto.Migration

  def change do
    alter table(:practitioner_accounts) do
      add :created_by_id, :binary_id
      add :updated_by_id, :binary_id
      add :step, :integer
    end
  end
end
