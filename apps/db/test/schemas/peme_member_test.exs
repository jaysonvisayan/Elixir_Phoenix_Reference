defmodule Innerpeace.Db.Schemas.PemeMemberTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.PemeMember
  alias Ecto.UUID

  test "changeset with valid attributes" do
    params = %{
      evoucher_number: "PEME-123456",
      evoucher_qrcode: "PEME-123456|Package-123",
      peme_id: "1232qwer",
      member_id: UUID.bingenerate()
    }

    changeset =
      %PemeMember{}
      |> PemeMember.changeset(params)

    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    params = %{
      evoucher_qrcode: "PEME-123456|Package-123",
      peme_id: "1232qwer",
      member_id: UUID.bingenerate()
    }

    changeset =
      %PemeMember{}
      |> PemeMember.changeset(params)

    refute changeset.valid?
  end
end
