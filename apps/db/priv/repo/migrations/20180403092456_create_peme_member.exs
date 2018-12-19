defmodule Innerpeace.Db.Repo.Migrations.CreatePemeMember do
  use Ecto.Migration

  def change do
    create table(:peme_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :peme_id, references(:pemes, type: :binary_id, on_delete: :nothing)
      add :member_id, references(:members, type: :binary_id, on_delete: :nothing)
      add :evoucher_number, :string
      add :evoucher_qrcode, :string

      timestamps()
    end
  end
end
