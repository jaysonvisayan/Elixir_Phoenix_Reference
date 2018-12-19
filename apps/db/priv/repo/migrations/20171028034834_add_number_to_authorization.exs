defmodule Innerpeace.Db.Repo.Migrations.AddNumberToAuthorization do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      add :number, :string
    end
    create unique_index(:authorizations, [:number])
  end
end
