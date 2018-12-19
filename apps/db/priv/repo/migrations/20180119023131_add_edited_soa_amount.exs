defmodule Innerpeace.Db.Repo.Migrations.AddEditedSoaAmount do
  use Ecto.Migration

  def change do
    alter table(:batches) do
      add :edited_soa_amount, :string
    end
  end
end
