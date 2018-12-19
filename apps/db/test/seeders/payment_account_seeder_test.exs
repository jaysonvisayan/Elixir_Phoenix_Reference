defmodule Innerpeace.Db.PaymentAccountSeederTest do
  use Innerpeace.Db.SchemaCase, async: false

  alias Innerpeace.Db.PaymentAccountSeeder

  test "seed account_group_address_address with new data" do
    account_group = insert(:account_group)
    [a1] = PaymentAccountSeeder.seed(data(account_group))
    assert a1.account_group_id == account_group.id
  end

  test "seed user with existing data" do
    account_group = insert(:account_group)
    insert(:payment_account)
    update_data = [
      %{
          payee_name: nil,
          account_group_id: account_group.id,
          account_tin: "1030232234234234",
          vat_status: "Full VAT-able",
          mode_of_payment: "Check",
          p_sched_of_payment: "DAILY",
          d_sched_of_payment: "ANNUAL",
          previous_carrier: "123412",
          attached_point: nil,
          revolving_fund: nil,
          threshold: nil,
          funding_arrangement: "ASO",
          authority_debit: false
      }
    ]
    [a1] = PaymentAccountSeeder.seed(update_data)
    assert a1.account_group_id == account_group.id
  end

  defp data(account_group) do
    [
      %{
          payee_name: nil,
          account_group_id: account_group.id,
          account_tin: "1030232234234234",
          vat_status: "Full VAT-able",
          mode_of_payment: "Check",
          p_sched_of_payment: "DAILY",
          d_sched_of_payment: "ANNUAL",
          previous_carrier: "123412",
          attached_point: nil,
          revolving_fund: nil,
          threshold: nil,
          funding_arrangement: "Full Risk",
          authority_debit: false
      }
    ]
  end

end
