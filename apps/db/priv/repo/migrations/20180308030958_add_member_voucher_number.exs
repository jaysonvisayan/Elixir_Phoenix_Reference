defmodule Innerpeace.Db.Repo.Migrations.AddMemberVoucherNumber do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add :evoucher_number, :string
      add :evoucher_qr_code, :string
    end
  end
end
