defmodule Innerpeace.Db.Base.EmailContextTest do
  use Innerpeace.Db.PayorRepo, :context
  use Innerpeace.{
    Db.SchemaCase,
  }

  alias Innerpeace.Db.Schemas.{
    Email
  }

  @invalid_attrs %{
    name: 13,
  }

  # create_fcontact_email start
  test "create facility contact email with valid attributes" do
    contact = insert(:contact,
      first_name: "Janna Mamer",
      last_name: "Dela Cruz",
      department: "SDDD",
      designation: "TL")

    email_params = %{
      type: "",
      address: "test@email.com",
      contact_id: contact.id
    }

    assert {:ok, %Email{}} = create_email(email_params)
  end

  test "create facility contact email  with invalid attributes" do
    assert {:error, %Ecto.Changeset{}} = create_email(@invalid_attrs)
  end
  # create_fcontact_email end
end
