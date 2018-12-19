defmodule Innerpeace.Db.Base.AccountGroupContextTest do
  use Innerpeace.Db.PayorRepo, :context
  use Innerpeace.Db.SchemaCase
  alias Innerpeace.Db.Schemas.AccountGroup

  test "insert_or_update_account_group * validates account_group" do
    account_group = insert(:account_group, name: "Sample")
    industry = insert(:industry)
    get_account_group = get_account_group_by_code(account_group.code)

    if is_nil(get_account_group) do
      params = %{
        name: "Account101",
        code: "CODE101",
        description: "Description",
        type: "Headquarters",
        segment: "Corporate",
        security: "Security",
        phone_no: "",
        email: "",
        remarks: "",
        #photo
        mode_of_payment: "",
        payee_name: "",
        account_no: "",
        account_name: "",
        branch: "",
        industry_id: industry.id,
        original_effective_date: Ecto.Date.cast!("2017-08-01")
      }
      assert {:ok, %AccountGroup{} = account_group} = create_an_account_group(params)
      assert account_group.industry_id == industry.id
    else
      params = %{
        name: "Account1012",
        code: "CODE101",
        type: "Headquarters",
        segment: "Corporate",
        industry_id: industry.id,
        original_effective_date: Ecto.Date.cast!("2017-08-01")
      }
      assert {:ok, %AccountGroup{} = account_group} = update_an_account_group(account_group, params)
      assert account_group.industry_id == industry.id
    end
  end

  test "get_account_group_by_code! returns the account_group with given account_group name" do
    account_group = insert(:account_group, name: "sample")
    assert get_account_group_by_code(account_group.code) == account_group
 end


 test "create_an_account_group * with valid data creates a account_group" do
    insert(:account_group)
    industry = insert(:industry)
    params = %{
      name: "Account101",
      code: "CODE101",
      description: "Description",
      type: "Headquarters",
      segment: "Corporate",
      security: "Security",
      phone_no: "",
      email: "",
      remarks: "",
      #photo
      mode_of_payment: "",
      payee_name: "",
      account_no: "",
      account_name: "",
      branch: "",
      industry_id: industry.id,
      original_effective_date: Ecto.Date.cast!("2017-08-01")
    }
    assert {:ok, %AccountGroup{} = account_group} = create_an_account_group(params)
    assert account_group.industry_id == industry.id
  end

  test "create_account_group with invalid data returns error changeset" do
    params = %{
      name: "Metropolitan Bank and Trust Company",
      account_no: "00001",
      account_status: "Active"
    }
    assert {:error, %Ecto.Changeset{}} = create_an_account_group(params)
  end

  test "update_account_group * with valid data updates the account_group" do
    account_group = insert(:account_group)
    industry = insert(:industry)
    params = %{
      name: "Account1012",
      code: "CODE101",
      type: "Headquarters",
      segment: "Corporate",
      industry_id: industry.id,
      original_effective_date: Ecto.Date.cast!("2017-08-01")
    }
    assert {:ok, %AccountGroup{} = account_group} = update_an_account_group(account_group, params)
    assert account_group.industry_id == industry.id
  end

  test "update_account_group with invalid data returns error changeset" do
    account_group = insert(:account_group)
    params = %{
      name: "Test",
    }
    assert {:error, %Ecto.Changeset{}} = update_an_account_group(account_group, params)
  end
end
