defmodule Innerpeace.Db.Base.ApiAddressContextTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Base.ApiAddressContext
  alias Ecto.UUID

  test "insert_or_update_api_address with existing name" do
    insert(:api_address, name: "PAYORLINK 1.0", address: "api.maxicare.com.ph")
    params = %{
      name: "PAYORLINK 1.0",
      address: "api.maxicare.com.ph",
      password: "test",
      username: "test"
    }

    {status, result} =
      params
      |> ApiAddressContext.insert_or_update_api_address()

    assert result.address == "api.maxicare.com.ph"
    assert status == :ok
  end

  test "insert_or_update_api_address without existing name" do
    params = %{
      name: "PAYORLINK 1.0",
      address: "api.maxicare.com.ph",
      password: "test",
      username: "test"
    }

    {status, result} =
      params
      |> ApiAddressContext.insert_or_update_api_address()

    assert result.address == "api.maxicare.com.ph"
    assert status == :ok
  end

  test "get_api_address_by_name with existing name" do
    api_address = insert(:api_address, name: "PAYORLINK 1.0", address: "api.maxicare.com.ph")
    result =
      "PAYORLINK 1.0"
      |> ApiAddressContext.get_api_address_by_name()

    assert result.address == api_address.address
  end

  test "get_api_address_by_name without existing name" do
    insert(:api_address, name: "PAYORLINK", address: "api.maxicare.com.ph")
    result =
      "PAYORLINK 1.0"
      |> ApiAddressContext.get_api_address_by_name()

    assert result == nil
  end

  test "create_api_address with valid params" do
    params = %{
      name: "PAYORLINK 1.0",
      address: "api.maxicare.com.ph",
      username: "test",
      password: "test"
    }
    {status, result} =
      params
      |> ApiAddressContext.create_api_address()

    assert status == :ok
    assert result.name == "PAYORLINK 1.0"
  end

  test "create_api_address with invalid params" do
    params = %{
      address: "api.maxicare.com.ph"
    }
    {status, _} =
      params
      |> ApiAddressContext.create_api_address()

    assert status == :error
  end

  test "update_api_address with valid params" do
    api_address = insert(:api_address, name: "PAYORLINK 1.0", address: "api.maxicare.com.ph")
    params = %{
      name: "PAYORLINK",
      username: "test",
      password: "test"
    }
    {status, result} =
      api_address.id
      |> ApiAddressContext.update_api_address(params)

    assert status == :ok
    assert result.name == "PAYORLINK"
  end

  test "update_api_address with invalid params" do
    api_address = insert(:api_address, address: "api.maxicare.com.ph")
    params = %{
      address: "api.maxicare.com.ph"
    }
    {status, _} =
      api_address.id
      |> ApiAddressContext.update_api_address(params)

    assert status == :error
  end

  test "get_api_address_by_id with valid params" do
    api_address = insert(:api_address, name: "PAYORLINK 1.0", address: "api.maxicare.com.ph")
    result =
      api_address.id
      |> ApiAddressContext.get_api_address_by_id()

    assert result.address == api_address.address
  end

  test "get_api_address_by_id with invalid params" do
    id = UUID.generate
    result =
      id
      |> ApiAddressContext.get_api_address_by_id()

    assert result == nil
  end

end
