defmodule Innerpeace.Db.Utilities.CardNoGeneratorTest do
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Utilities.CardNoGenerator
  # alias Ecto.UUID

  @card_bin "60508311"
  @invalid_card_bin "6050831"
  @sequence 1293

  test "generate_card_number returns valid card number" do
    payor = insert(:payor)
    payor_card_bin = insert(:payor_card_bin, payor: payor,
                            card_bin: @card_bin, sequence: @sequence)

    result = CardNoGenerator.generate_card_number(payor_card_bin.payor_id)

    assert result == "6050831100012933"
  end

  # uncomment once payor_id is available
  # test "generate_card_number with invalid payor_id"  do
  #   id = UUID.generate()

  #   result = CardNoGenerator.generate_card_number(id)
  #   assert result == {:error, "Payor card bin not registered"}
  # end

  test "generate_card_number returns invalid card bin length" do
    payor = insert(:payor)
    payor_card_bin = insert(:payor_card_bin, payor: payor,
                            card_bin: @invalid_card_bin, sequence: @sequence)

    result = CardNoGenerator.generate_card_number(payor_card_bin.payor_id)

    assert result == {:error, "Invalid card bin length"}
  end

  test "generate_card_number_mod_10 returns invalid card number base length" do
    sequence =
      @sequence
      |> Integer.to_string
      |> String.pad_leading(6, "0")

    result = CardNoGenerator.generate_card_number_mod_10("#{@card_bin}#{sequence}")

    assert result == {:error, "Invalid card number base length"}
  end

  test "card_number_sum with valid params" do
    sequence =
      @sequence
      |> Integer.to_string
      |> String.pad_leading(7, "0")

    result = CardNoGenerator.card_number_sum(Enum.reverse(
      String.graphemes("#{@card_bin}#{sequence}")), 0)

    assert result == 37
  end

  test "sum_number with valid params" do
    number = ["1", "2"]
    result = CardNoGenerator.sum_number(number)
    assert result == 3
  end
end
