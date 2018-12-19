defmodule Innerpeace.Db.Repo.Migrations.AddCopEffectiveDateInMember do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add :cop_effective_date, :date
    end
  end
end
