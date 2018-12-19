defmodule Innerpeace.Db.Repo.Migrations.ChangeOnDeleteInFacility do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE facility_location_groups DROP CONSTRAINT facility_location_groups_facility_id_fkey"
    alter table(:facility_location_groups) do
      modify :facility_id, references(:facilities, type: :binary_id, on_delete: :delete_all)
    end

    execute "ALTER TABLE emails DROP CONSTRAINT emails_contact_id_fkey"
    alter table(:emails) do
      modify :contact_id, references(:contacts, type: :binary_id, on_delete: :delete_all)
    end

    execute "ALTER TABLE facility_contacts DROP CONSTRAINT facility_contacts_contact_id_fkey"
    alter table(:facility_contacts) do
      modify :contact_id, references(:contacts, type: :binary_id, on_delete: :delete_all)
    end
  end

  def down do
    execute "ALTER TABLE facility_location_groups DROP CONSTRAINT facility_location_groups_facility_id_fkey"
    alter table(:facility_location_groups) do
      modify :facility_id, references(:facilities, type: :binary_id)
    end

    execute "ALTER TABLE emails DROP CONSTRAINT emails_contact_id_fkey"
    alter table(:emails) do
      modify :contact_id, references(:contacts, type: :binary_id)
    end

    execute "ALTER TABLE facility_contacts DROP CONSTRAINT facility_contacts_contact_id_fkey"
    alter table(:facility_contacts) do
      modify :contact_id, references(:contacts, type: :binary_id, on_delete: :nothing)
    end
  end
end
