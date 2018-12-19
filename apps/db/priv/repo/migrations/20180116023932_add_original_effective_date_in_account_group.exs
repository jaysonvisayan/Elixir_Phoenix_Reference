defmodule Innerpeace.Db.Repo.Migrations.AddOriginalEffectiveDateInAccountGroup do
  use Ecto.Migration

  def change do

    alter table(:account_groups) do
      add :original_effective_date, :date
    end

  end
end
