defmodule :"Elixir.Innerpeace.Db.Repo.Migrations.AlterKycBankMaiden-first-middle-lastName" do
  use Ecto.Migration

  def change do
    alter table(:kyc_banks) do
      add :mm_first_name, :string
      add :mm_middle_name, :string
      add :mm_last_name, :string
      add :others, :string
    end
  end
end
