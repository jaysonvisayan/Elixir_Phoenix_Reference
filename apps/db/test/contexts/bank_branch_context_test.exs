defmodule Innerpeace.Db.Base.BankBranchContextTest do
  use Innerpeace.Db.PayorRepo, :context
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.BankBranch

  test "insert_or_update_bank_branch * validates bank_branch" do

  end

  test "get_bank_branch_by_id! returns the bank_branch with given bank id" do
    bank = insert(:bank)
    bank_branch = insert(:bank_branch, branch_type: "Main Branch")
    assert get_bank_branch_by_id(bank.id) == bank_branch.bank_id
  end

 test "create_bank_branch * with valid data creates a bank_branch" do
    insert(:bank_branch)
    bank = insert(:bank)
    insert(:account_group)
    params = %{
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
    assert {:ok, %BankBranch{} = bank_branch} = create_bank_branch(params)
    assert bank_branch.branch_type == "Main branch"
  end

  test "create_bank_branch with invalid data returns error changeset" do
    params = %{
      phone: "444-38-56"
    }
    assert {:error, %Ecto.Changeset{}} = create_bank_branch(params)
  end

  test "update_bank_branch * with valid data updates the bank_branch" do
    bank_branch = insert(:bank_branch)
    insert(:account_group)
    params = %{
      branch_type: "Headquarters"
    }
    assert {:ok, %BankBranch{}} = update_bank_branch(bank_branch, params)
  end

  test "update_bank_branch with invalid data returns error changeset" do
    bank_branch = insert(:bank_branch)
    params = %{
      phone: "444-38-56"
    }
    assert {:error, %Ecto.Changeset{}} = update_bank_branch(bank_branch, params)
  end

end
