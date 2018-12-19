defmodule Innerpeace.Db.BankBranchSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.BankBranchSeeder
  @branch_type "Main branch"

  test "seed bank branch with new data" do
    bank = insert(:bank)
    [bb1] = BankBranchSeeder.seed(data(bank))
    assert bb1.branch_type == @branch_type
  end

  test "seed bank branch with existing data" do
    bank = insert(:bank)
    data = [
      %{
      bank_id: bank.id,
      unit_no: "5b",
      bldg_name: "Cacho Gonzalez Bldg.",
      street_name: "Aguirre st.",
      municipality: "Makati City",
      province: "N/A",
      region: "NCR",
      country: "PHILIPPINES",
      postal_code: "1661",
      phone: "444-38-56",
      branch_type: "Main branch"
      }
    ]
    [bb1] = BankBranchSeeder.seed(data)
    assert bb1.branch_type == @branch_type
  end

  defp data(bank) do
    [
      %{
      bank_id: bank.id,
      unit_no: "5b",
      bldg_name: "Cacho Gonzalez Bldg.",
      street_name: "Aguirre st.",
      municipality: "Makati City",
      province: "N/A",
      region: "NCR",
      country: "PHILIPPINES",
      postal_code: "1661",
      phone: "444-38-56",
      branch_type: "Main branch"

      }
    ]
  end

end
