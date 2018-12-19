defmodule Innerpeace.Db.Base.ApiAddressTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.ApiAddress

  test "changeset with valid params" do
    params = %{
      name: "PAYORLINK",
      address: "payorlink.com.ph",
      username: "test",
      password: "test"
    }

    result =
      %ApiAddress{}
      |> ApiAddress.changeset(params)

    assert result.valid?
  end

  test "changeset with invalid params" do
    params = %{
      name: "PAYORLINK"
    }

    result =
      %ApiAddress{}
      |> ApiAddress.changeset(params)

    refute result.valid?
  end
end
