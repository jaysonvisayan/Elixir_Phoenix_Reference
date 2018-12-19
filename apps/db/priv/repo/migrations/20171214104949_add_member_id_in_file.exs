defmodule Innerpeace.Db.Repo.Migrations.AddMemberIdInFile do
  use Ecto.Migration

  def change do
    alter table(:files) do
      add :member_id, references(:members, type: :binary_id, on_delete: :delete_all)
    end
  end
end
