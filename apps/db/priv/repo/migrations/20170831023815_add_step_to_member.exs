defmodule Innerpeace.Db.Repo.Migrations.AddStepToMember do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add :step, :integer
      add :relationship, :string
    end
    create unique_index(:members, [:email])
    create unique_index(:members, [:mobile])
  end
end
