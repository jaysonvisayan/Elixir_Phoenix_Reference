defmodule Innerpeace.Db.Repo.Migrations.AddSuffixInContacts do
  use Ecto.Migration

  def change do
    alter table(:contacts) do
      add :suffix, :string
    end
  end
end

