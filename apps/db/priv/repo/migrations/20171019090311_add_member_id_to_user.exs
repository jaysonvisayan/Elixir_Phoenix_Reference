defmodule Innerpeace.Db.Repo.Migrations.AddMemberIdToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :member_id, references(:members, type: :binary_id, on_delete: :delete_all)
    end
    create index(:users, [:member_id])
  end
end
