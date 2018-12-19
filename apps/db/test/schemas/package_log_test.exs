defmodule Innerpeace.Db.Schemas.PackageLogTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.PackageLog

  test "changeset with valid attributes" do
    params = %{
      package_id: Ecto.UUID.generate(),
      user_id: Ecto.UUID.generate(),
      message: Ecto.UUID.generate()
    }
    changeset = PackageLog.changeset(%PackageLog{}, params)
    assert changeset.valid?
  end
end
