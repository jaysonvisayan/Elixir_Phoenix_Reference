defmodule Innerpeace.Db.Schemas.PayorTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.Payor

  test "changeset with valid attributes" do
    params = %{
      name: "some content",
      legal_name: "some content",
      tax_number: 123,
      type: "some content",
      status: "some content",
      code: "some content"
    }

    changeset = Payor.changeset(%Payor{}, params)
    assert changeset.valid?
  end

end

