defmodule Innerpeace.Db.Repo.Migrations.AddPractitionerAndRoomIdInAuthorizationProcedureDiagnosis do
  use Ecto.Migration

  def up do
    alter table(:authorization_procedure_diagnoses) do
      add :authorization_room_id, references(:authorization_rooms, type: :binary_id, on_delete: :delete_all)
    end
  end

  def down do
    alter table(:authorization_procedure_diagnoses) do
      remove :authorization_room_id
    end
  end
end
