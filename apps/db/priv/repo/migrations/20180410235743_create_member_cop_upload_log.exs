defmodule Innerpeace.Db.Repo.Migrations.CreateMemberCopUploadLog do
  @moduledoc """
    Migration File for Member's Change of Product Upload File Log.
  """
  use Ecto.Migration

  def change do
    create table(:member_cop_upload_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :change_of_product_effective_date, :string
      add :old_product_code, :string
      add :new_product_code, :string
      add :reason, :text
      add :status, :string
      add :upload_status, :text
      add :member_id, :string

      add :member_upload_file_id, references(:member_upload_files, type: :binary_id, on_delete: :delete_all)
      add :created_by_id, references(:users, type: :binary_id)

      timestamps()
    end
    create index(:member_cop_upload_logs, [:member_upload_file_id])
  end
end
