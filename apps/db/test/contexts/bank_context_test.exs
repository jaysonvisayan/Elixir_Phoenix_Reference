defmodule Innerpeace.Db.Base.BankContextTest do
  use Innerpeace.Db.PayorRepo, :context
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.Bank

  test "insert_or_update_bank * validates bank" do
    bank = insert(:bank, account_name: "sample", account_no: "sample")
    account_group = insert(:account_group)
    get_bank = get_bank_by_name_and_no(bank.account_name, bank.account_no)

    if is_nil(get_bank) do
      params = %{
        account_name: "Metropolitan Bank and Trust Company",
        account_no: "00001",
        account_status: "Active",
        account_group_id: account_group.id
      }
      assert {:ok, %Bank{} = bank} = create_bank(params)
      assert bank.account_group_id == account_group.id
    else
      params = %{
        account_name: "Test",
        account_no: "00001",
        account_status: "Active",
        account_group_id: account_group.id
      }
      assert {:ok, %Bank{} = bank} = update_bank(bank, params)
      assert bank.account_group_id == account_group.id
    end
  end

  test "get_bank_by_name! returns the bank with given bank name" do
    bank = insert(:bank, account_name: "sample", account_no: "sample")
    assert bank.account_name |> get_bank_by_name_and_no(bank.account_no) |> Repo.preload([:account_group]) == bank
 end

 test "create_an_bank * with valid data creates a bank" do
    insert(:bank)
    account_group = insert(:account_group)
    params = %{
      account_name: "Metropolitan Bank and Trust Company",
      account_no: "00001",
      account_status: "Active",
      account_group_id: account_group.id
    }
    assert {:ok, %Bank{} = bank} = create_bank(params)
    assert bank.account_group_id == account_group.id
  end

  test "create_bank with invalid data returns error changeset" do
    params = %{
      account_name: "Metropolitan Bank and Trust Company",
      account_no: "00001",
      account_status: "Active"
    }
    assert {:error, %Ecto.Changeset{}} = create_bank(params)
  end

  test "update_bank * with valid data updates the bank" do
    bank = insert(:bank)
    account_group = insert(:account_group)
    params = %{
      account_name: "Test",
      account_no: "00001",
      account_status: "Active",
      account_group_id: account_group.id
    }
    assert {:ok, %Bank{} = bank} = update_bank(bank, params)
    assert bank.account_group_id == account_group.id
  end

#  test "update_bank with invalid data returns error changeset" do
#    bank = insert(:bank)
#    params = %{
#      account_name: "Test",
#    }
#    assert {:error, %Ecto.Changeset{}} = update_bank(bank, params)
#  end

end
