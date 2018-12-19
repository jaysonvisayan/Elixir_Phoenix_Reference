defmodule Innerpeace.Db.Repo.Migrations.AddSalutationInMembers do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add :salutation, :string
    end
  end
end
