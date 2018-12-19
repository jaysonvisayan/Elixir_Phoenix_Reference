defmodule Innerpeace.Db.ContactSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.ContactSeeder

  test "seed contact_address with new data" do
    insert(:contact)
    [a1] = ContactSeeder.seed(data())
    assert a1.last_name == "Jollibee Corporation"
  end

  test "seed user with existing data" do
    insert(:contact)
    update_data = [
      %{
          last_name: "Jollibee Corporation",
          first_name: "First Name",
          department: nil,
          designation: "Testing",
          email: "jollibee_corporation@gmail.com",
          ctc: "TESTCTC",
          ctc_date_issued: Ecto.Date.cast!("2017-08-01"),
          ctc_place_issued: "TEST PLACE CTC",
          passport_no: "TESTNUMBER",
          passport_date_issued: Ecto.Date.cast!("2017-08-01"),
          passport_place_issued: "TEST PLACE PASSPORT",
          type: "Corp Signatory"
      }
    ]
    [a1] = ContactSeeder.seed(update_data)
    assert a1.last_name == "Jollibee Corporation"
  end

  defp data() do
    [
      %{
          last_name: "Jollibee Corporation",
          first_name: "First Name",
          department: nil,
          designation: "Testing",
          email: "jollibee_corporation@gmail.com",
          ctc: "TESTCTC",
          ctc_date_issued: Ecto.Date.cast!("2017-08-01"),
          ctc_place_issued: "TEST PLACE CTC",
          passport_no: "TESTNUMBER",
          passport_date_issued: Ecto.Date.cast!("2017-08-01"),
          passport_place_issued: "TEST PLACE PASSPORT",
          type: "Contact Person"
      }
    ]
  end

end
