defmodule Innerpeace.Db.Schemas.RUVLogTest do
  use Innerpeace.Db.SchemaCase

  alias Ecto.UUID
  alias Innerpeace.Db.Schemas.RUVLog

  test "changset with valid attributes" do
    params = %{
      message: "test message",
      user_id: UUID.bingenerate(),
      ruv_id: UUID.bingenerate()
    }

    changeset = RUVLog.changeset(%RUVLog{}, params)
    assert changeset.valid?
  end

  test "changset with invalid attributes" do
    params = %{
      message: "test message",
    }

    changeset = RUVLog.changeset(%RUVLog{}, params)
    refute changeset.valid?
  end
end
