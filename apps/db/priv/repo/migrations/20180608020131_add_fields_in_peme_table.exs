defmodule Innerpeace.Db.Repo.Migrations.AddFieldsInPemeTable do
  use Ecto.Migration

  def change do
    alter table(:pemes) do
      add :member_id, references(:members, type: :binary_id, on_delete: :delete_all)
      add :evoucher_number, :string
      add :evoucher_qrcode, :string
      add :registration_date, :date
    end
  end
end
