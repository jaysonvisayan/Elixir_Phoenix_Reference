defmodule Innerpeace.Db.Schemas.PractitionerScheduleTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.PractitionerSchedule

  test "changeset with valid attributes" do
    params = %{
      day: "Monday",
      room: "asd",
      time_from: Ecto.Time.utc(),
      time_to: Ecto.Time.utc(),
      practitioner_account_id: Ecto.UUID.generate()
    }

    changeset = PractitionerSchedule.changeset_pa(%PractitionerSchedule{}, params)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      day: "Monday",
      time_from: "27:00:00",
      time_to: Ecto.Time.utc(),
      practitioner_account_id: Ecto.UUID.generate()
    }

    changeset = PractitionerSchedule.changeset_pa(%PractitionerSchedule{}, params)
    refute changeset.valid?
  end

end
