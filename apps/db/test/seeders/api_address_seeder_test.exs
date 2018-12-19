defmodule Innerpeace.Db.ApiAddressSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.ApiAddressSeeder

  @name "PAYORLINK"
  @address "https://payorlink.com.ph/"

  test "seed api address with new data" do
    params = [%{
      name: @name,
      address: @address
    }]

    [aa1] =
      params
      |> ApiAddressSeeder.seed()
    assert aa1.name == @name
  end

  test "seed api address with existing data" do
    insert(:api_address, name: @name, address: @address)
    params = [%{
      name: "PAYLINK"
    }]

    [aa1] =
      params
      |> ApiAddressSeeder.seed()
    assert aa1.name == "PAYLINK"
  end
end
