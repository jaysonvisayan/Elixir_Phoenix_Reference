defmodule Innerpeace.Db.Repo.Migrations.AddVatStatusIdInPractitonersTable do
  use Ecto.Migration

  def up do
  	alter table(:practitioners) do
      add :vat_status_id, references(:dropdowns, type: :binary_id)
    end
  end

  def down do
    execute "ALTER TABLE practitioners DROP CONSTRAINT practitioners_vat_status_id_fkey"
    alter table(:practitioners) do
      remove :vat_status_id
    end
  end

end
