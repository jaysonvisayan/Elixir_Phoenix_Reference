defmodule Innerpeace.Db.Base.PhoneContextTest do
  use Innerpeace.Db.PayorRepo, :context
  use Innerpeace.{
    Db.SchemaCase,
  }

  alias Innerpeace.Db.Schemas.{
    Phone
  }

  @invalid_attrs %{
    name: 13,
  }

  # create_fcontact_phone start
  test "create facility contact phone with valid attributes" do
    contact = insert(:contact,
      first_name: "Janna Mamer",
      last_name: "Dela Cruz",
      department: "SDDD",
      designation: "TL")

    phone_params = %{
      type: "mobile",
      number: "09876543211",
      contact_id: contact.id
    }

    assert {:ok, %Phone{}} = create_phone(phone_params)
  end

  test "create facility contact phone  with invalid attributes" do
    assert {:error, %Ecto.Changeset{}} = create_phone(@invalid_attrs)
  end
  # create_fcontact_phone end

end
