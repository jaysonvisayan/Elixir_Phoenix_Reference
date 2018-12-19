defmodule Innerpeace.Db.Repo.Migrations.AddMembersSenior do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add :senior_id, :string
      add :senior_photo, :string
      add :pwd_id, :string
      add :pwd_photo, :string
    end
  end
end
