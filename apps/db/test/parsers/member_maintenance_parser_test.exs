defmodule Innerpeace.Db.Parsers.MemberMaintenanceParserTest do
  use Innerpeace.Db.SchemaCase, async: true
  # alias Innerpeace.Db.{
  #   Repo,
  #   Schemas.Member
  # }
  alias Innerpeace.Db.Parsers.MemberMaintenanceParser
  setup do
    user = insert(:user)
    account_group = insert(:account_group, name: "ACCOUNT101", code: "ACC101")
    active_member = insert(:member, first_name: "Jayson",
                    last_name: "Visayan",
                    employee_no: "1234567891",
                    card_no: "0987654321",
                    status: "Active", type: "Principal",
                    step: 5,
                    account_code: account_group.code,
                    effectivity_date: Ecto.Date.cast!("1990-01-01"),
                    expiry_date: Ecto.Date.cast!("2090-02-02")
    )

    suspend_member = insert(:member, first_name: "Jayson",
                    last_name: "Visayan",
                    employee_no: "1234567890",
                    card_no: "0987654321",
                    status: "Suspended", type: "Principal",
                    step: 5,
                    account_code: account_group.code,
                    effectivity_date: Ecto.Date.cast!("1990-01-01"),
                    expiry_date: Ecto.Date.cast!("2090-02-02")
    )
    _account = insert(:account,
                     account_group: account_group,
                     start_date: Ecto.Date.cast!("1990-01-01"),
                     end_date: Ecto.Date.cast!("2019-02-02"),
                      status: "Active")
    date = Date.utc_today
    date = "#{date.month }/#{date.day}/#{date.year + 1}"

    {:ok, %{active_member: active_member,
      suspend_member: suspend_member, user: user, date: date}}
  end

  test "suspend_validation returns passed suspend member by batch upload", %{active_member: member, date: date} do
    suspend_params = %{
      "Member Name" =>  "jayson visayan",
      "Member ID" => member.id,
      "Employee No" => member.employee_no,
      "Card No" => member.card_no,
      "Suspension Date" => date,
      "Reason" => "Reason 1"
    }
    data = MemberMaintenanceParser.suspend_validations(1, suspend_params, [])
    assert {:passed} == data
  end

  test "cancel_validation returns passed cancel member by batch upload", %{active_member: member, date: date} do
    cancel_params = %{
      "Member Name" =>  "jayson visayan",
      "Member ID" => member.id,
      "Employee No" => member.employee_no,
      "Card No" => member.card_no,
      "Cancellation Date" => date,
      "Reason" => "Reason 1"
    }
    data = MemberMaintenanceParser.cancel_validations(1, cancel_params, [])
    assert {:passed} == data
  end

  test "reactivate_validation returns passed reactivate member by batch upload", %{suspend_member: member, date: date} do
    reactivate_params = %{
      "Member Name" =>  "jayson visayan",
      "Member ID" => member.id,
      "Employee No" => member.employee_no,
      "Card No" => member.card_no,
      "Reactivation Date" => date,
      "Reason" => "Reason 1"
    }
    data = MemberMaintenanceParser.reactivate_validations(1,
                                                          reactivate_params, [])
    assert {:passed} == data
  end

  test "validate_columns/1 success", %{active_member: member, date: date} do
    params = %{
      "Member Name" =>  "jayson visayan",
      "Member ID" => member.id,
      "Employee No" => member.employee_no,
      "Card No" => member.card_no,
      "Suspension Date" => date,
      "Reason" => "Reason 1"
    }
    assert {:complete} = MemberMaintenanceParser.validate_columns(params)
  end

  test "validate_columns/1 failed", %{active_member: member} do
    params = %{
      "Member Name" =>  "jayson visayan",
      "Member ID" => member.id,
      "Employee No" => member.employee_no,
      "Card No" => member.card_no,
      "Suspension Date" => "",
      "Reason" => "Reason 1"
    }
    assert {:missing, "Please enter Suspension Date"} = MemberMaintenanceParser.validate_columns(params)
  end

  test "validate_member/1 success", %{active_member: member} do
    params = %{
      "Member Name" =>  "jayson visayan",
      "Member ID" => member.id,
      "Employee No" => member.employee_no,
      "Card No" => member.card_no,
      "Suspension Date" => "",
      "Reason" => "Reason 1"
    }
    assert {:valid_member} = MemberMaintenanceParser.validate_member(params)
  end

  test "validate_member/1 failed", %{active_member: _member} do
    params = %{
      "Member ID" => Ecto.UUID.generate(),
      "Suspension Date" => "",
      "Reason" => "Reason 1"
   }
   assert {:invalid_member} = MemberMaintenanceParser.validate_member(params)
  end

  test "validate_cancelation_date returns valid_cancel_date when date is valid", %{active_member: member, date: date} do
    date = MemberMaintenanceParser.validate_cancellation_date(date, member.id)
    assert {:valid_cancel_date} == date
  end

  test "validate_cancelation_date returns invalid_date_format when date is invalid", %{active_member: member} do
    date = MemberMaintenanceParser.validate_cancellation_date("123/12/2017", member.id)
    assert {:invalid_date_format} == date
  end

  test "validate_suspension_date returns valid_suspend_date when date is valid", %{active_member: member, date: date} do
    date = MemberMaintenanceParser.validate_suspension_date(date, member.id)
    assert {:valid_suspend_date} == date
  end

  test "validate_suspension_date returns invalid_date_format when date is invalid", %{active_member: member} do
    date = MemberMaintenanceParser.validate_suspension_date("122/12/2017", member.id)
    assert {:invalid_date_format} == date
  end

  test "validate_reactivation_date returns valid_reactivate_date when date is valid", %{suspend_member: member, date: date} do
    date = MemberMaintenanceParser.validate_reactivation_date(date, member.id)
    assert {:valid_reactivate_date} == date
  end

  test "validate_reactivate_date returns invalid_date_format when date is invalid", %{active_member: member} do
    date = MemberMaintenanceParser.validate_reactivation_date("122/12/2017", member.id)
    assert {:invalid_date_format} == date
  end
end
