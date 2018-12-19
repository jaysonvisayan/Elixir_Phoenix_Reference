defmodule :"Elixir.Innerpeace.Db.Repo.Migrations.Alter-kycbank-table-add-email-and-mobile" do
  use Ecto.Migration

  def change do
    alter table(:kyc_banks) do
      add :email1, :string
      add :email2, :string
      add :mobile1, :string
      add :mobile2, :string
    end
  end
end
