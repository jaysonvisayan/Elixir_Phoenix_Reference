defmodule Innerpeace.Db.Repo.Migrations.CreateMemberDocumentsTbl do
  use Ecto.Migration

  def up do
    create table(:member_documents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :content_type, :string
      add :link, :string
      add :purpose, :string
      add :uploaded_from, :string
      add :date_uploaded, :date
      add :authorization_id, references(:authorizations, type: :binary_id, on_delete: :delete_all)
      add :member_id, references(:members, type: :binary_id, on_delete: :delete_all)
      add :uploaded_by, :string

      timestamps()
    end
    create index(:member_documents, [:member_id])
    create index(:member_documents, [:authorization_id])
  end

  def down do
    drop table(:member_documents)
  end

end
