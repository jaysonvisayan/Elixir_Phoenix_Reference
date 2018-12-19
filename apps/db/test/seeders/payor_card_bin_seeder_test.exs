defmodule Innerpeace.Db.PayorCardBinSeederTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.PayorCardBinSeeder

  @card_bin "60508311"
  @sequence 1

  test "seed payor card bin with new data" do
    payor = insert(:payor)

    data = [
      %{
        card_bin: @card_bin,
        sequence: @sequence,
        payor_id: payor.id
      }
    ]

    [pcb1] = PayorCardBinSeeder.seed(data)
    assert pcb1.card_bin == @card_bin
  end

  test "seed payor card bin with existing data" do
    payor = insert(:payor)
    insert(:payor_card_bin, card_bin: @card_bin,
           sequence: @sequence, payor: payor)

    data = [
      %{
        card_bin: "60508312",
        payor_id: payor.id
      }
    ]

    [pcb1] = PayorCardBinSeeder.seed(data)
    assert pcb1.card_bin == "60508312"
  end
end
