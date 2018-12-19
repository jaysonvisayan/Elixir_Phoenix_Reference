defmodule Innerpeace.Db.Schemas.ProfileCorrectionTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.ProfileCorrection

#   test "changeset with valid params" do
#     params = %{
#       "status" => "for approval",
#       "id_card" => "test",
#       "first_name" => "test"
#     }

#     changeset =
#       %ProfileCorrection{}
#       |> ProfileCorrection.changeset(params)

#     assert changeset.valid?
#   end

  test "changeset with invalid params" do
    params = %{
      "status" => "for approval",
      "id_card" => "test"
    }

    changeset =
      %ProfileCorrection{}
      |> ProfileCorrection.changeset(params)

    refute changeset.valid?
  end
end
