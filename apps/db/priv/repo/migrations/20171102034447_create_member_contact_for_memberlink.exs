defmodule Innerpeace.Db.Repo.Migrations.CreateMemberContactForMemberlink do
  use Ecto.Migration

  def change do
    create table(:member_contacts, primary_key: false)  do
      add :id, :binary_id, primary_key: true
      add :member_id, references(:members, type: :binary_id, on_delete: :delete_all)
      add :contact_id, references(:contacts, type: :binary_id, on_delete: :delete_all)
      timestamps()
    end
    create index(:member_contacts,[:member_id, :contact_id])
  end
end
