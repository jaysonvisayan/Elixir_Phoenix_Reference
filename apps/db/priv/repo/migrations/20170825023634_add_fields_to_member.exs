defmodule Innerpeace.Db.Repo.Migrations.AddFieldsToMember do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add :status, :string
      add :member_id, :string
      add :card_no, :string
    end
  end
end
