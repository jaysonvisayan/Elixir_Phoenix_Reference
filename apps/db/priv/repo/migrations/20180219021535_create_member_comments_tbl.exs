defmodule Innerpeace.Db.Repo.Migrations.CreateMemberCommentsTbl do
  use Ecto.Migration

  def change do
    create table(:member_comments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :comment, :string
      add :member_id, references(:members, type: :binary_id, on_delete: :nothing)
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps()
    end

    create index(:member_comments, [:member_id])
  end
end
