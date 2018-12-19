defmodule Innerpeace.Db.PhoneSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.PhoneSeeder

  test "seed with new data" do
    contact = insert(:contact)
    [a1] = PhoneSeeder.seed(data(contact))
    assert a1.contact_id == contact.id
  end

  test "seed with existing data" do
    contact = insert(:contact)
    insert(:phone)
    update_data = [
      %{
        contact_id: contact.id,
        number: "09123456789",
        type: "mobile"
      }
    ]
    [a1] = PhoneSeeder.seed(update_data)
    assert a1.contact_id == contact.id
  end

  defp data(contact) do
    [
      %{
        contact_id: contact.id,
        number: "09111212121",
        type: "mobile"
      }
    ]
  end

end
