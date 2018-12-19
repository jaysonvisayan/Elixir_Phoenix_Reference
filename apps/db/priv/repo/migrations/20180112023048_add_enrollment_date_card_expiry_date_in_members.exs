defmodule Innerpeace.Db.Repo.Migrations.AddEnrollmentDateCardExpiryDateInMembers do
  use Ecto.Migration

  def up do
    alter table(:members) do
      add :enrollment_date, :date
      add :card_expiry_date, :date
    end
  end

  def down do
    alter table(:members) do
      remove :enrollment_date
      remove :card_expiry_date
    end
  end
end
