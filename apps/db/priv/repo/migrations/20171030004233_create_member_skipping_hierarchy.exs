defmodule Innerpeace.Db.Repo.Migrations.CreateMemberSkippingHierarchy do
  use Ecto.Migration

  def change do
    create table(:member_skipping_hierarchy, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :member_id, references(:members, type: :binary_id)
      add :first_name, :string
      add :middle_name, :string
      add :last_name, :string
      add :gender, :string
      add :relationship, :string
      add :suffix, :string
      add :reason, :string
      add :supporting_document, :string
      add :birthdate, :date

      timestamps()
    end
    create index(:member_skipping_hierarchy, [:member_id])
  end

end

