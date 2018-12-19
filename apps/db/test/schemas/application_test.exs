defmodule Innerpeace.Db.Schemas.ApplicationTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Application

  test "changeset with valid attributes" do
    params = %{
      name: "application"
    }

    changeset = Application.changeset(%Application{}, params)
    assert changeset.valid?
  end
end
