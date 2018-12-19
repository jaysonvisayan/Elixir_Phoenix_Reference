defmodule Innerpeace.Db.Base.PayorCardBinContextTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Base.PayorCardBinContext
  alias Ecto.UUID

  test "insert_or_update_payor_card_bin with new payor card bin" do
    payor = insert(:payor)
    params = %{
      payor_id: payor.id,
      card_bin: "60508311",
      sequence: 1
    }

    {status, result} =
      PayorCardBinContext.insert_or_update_payor_card_bin(params)
    assert result.card_bin == "60508311"
    assert status == :ok
  end

  test "insert_or_update_payor_card_bin with existing payor card bin" do
    payor = insert(:payor)
    insert(:payor_card_bin, payor: payor, card_bin: "60508311", sequence: 1)

    params = %{
      card_bin: "60508312",
      payor_id: payor.id
    }

    {status, result} =
      PayorCardBinContext.insert_or_update_payor_card_bin(params)
    assert result.card_bin == "60508312"
    assert status == :ok
  end

  test "insert_or_update_payor_card_bin with invalid params" do
    payor = insert(:payor)
    params = %{
      payor_id: payor.id,
      card_bin: 60_508_311,
      sequence: 1
    }

    {status, result} =
      PayorCardBinContext.insert_or_update_payor_card_bin(params)
    refute result.valid?
    assert status == :error
  end

  test "create_payor_card_bin with valid params" do
    payor = insert(:payor)
    params = %{
      payor_id: payor.id,
      card_bin: "60508311",
      sequence: 1
    }

    {status, result} =
      PayorCardBinContext.create_payor_card_bin(params)
    assert result.card_bin == "60508311"
    assert status == :ok
  end

  test "create_payor_card_bin with invalid params" do
    payor = insert(:payor)
    params = %{
      payor_id: payor.id,
      card_bin: 60_508_311,
      sequence: 1
    }

    {status, result} =
      PayorCardBinContext.create_payor_card_bin(params)
    refute result.valid?
    assert status == :error
  end

  test "update_payor_card_bin with valid params" do
    payor = insert(:payor)
    payor_card_bin = insert(:payor_card_bin, payor: payor,
                            card_bin: "60508311", sequence: 1)

    params = %{
      card_bin: "60508312",
      payor_id: payor.id
    }

    {status, result} =
      PayorCardBinContext.update_payor_card_bin(payor_card_bin.id, params)
    assert result.card_bin == "60508312"
    assert status == :ok
  end

  test "update_payor_card_bin with invalid params" do
    payor = insert(:payor)
    payor_card_bin = insert(:payor_card_bin, payor: payor,
                            card_bin: "60508311", sequence: 1)

    params = %{
      card_bin: 60_508_312,
      payor_id: payor.id
    }

    {status, result} =
      PayorCardBinContext.update_payor_card_bin(payor_card_bin.id, params)
    refute result.valid?
    assert status == :error
  end

  test "get_payor_card_bin_by_id with valid params" do
    payor = insert(:payor)
    payor_card_bin = insert(:payor_card_bin, payor: payor)
    result =
      PayorCardBinContext.get_payor_card_bin_by_id(payor_card_bin.id)

    assert result.payor_id == payor.id
  end

  test "get_payor_card_bin_by_id with invalid params" do
    id = UUID.generate

    result =
      PayorCardBinContext.get_payor_card_bin_by_id(id)
    assert result == nil
  end

  test "get_payor_card_bin_by_payor_id with valid payor id" do
    payor = insert(:payor)
    insert(:payor_card_bin, payor: payor)
    result =
      PayorCardBinContext.get_payor_card_bin_by_payor_id(payor.id)

    assert result.payor_id == payor.id
  end

  test "get_payor_card_bin_by_payor_id with invalid payor id" do
    id = UUID.generate

    result =
      PayorCardBinContext.get_payor_card_bin_by_payor_id(id)

    assert result == nil
  end
end
