defmodule Innerpeace.Db.Parsers.UserAccessActivationParserTest do
  use Innerpeace.Db.SchemaCase, async: true
  alias Innerpeace.Db.Parsers.UserAccessActivationParser, as: UAAP

  @valid_attrs %{
    "Code" => "C00918",
    "Employee Name" => "1234-5678"
  }

  setup do
    user = insert(:user, payroll_code: "C00918")
    uaaf = insert(:user_access_activation_file)
    insert(:user_access_activation_log, user_access_activation_file: uaaf)
    {:ok, %{
      user: user,
      uaaf: uaaf
    }}
  end

  test "Parse data", %{uaaf: uaaf} do
    params = Map.put(@valid_attrs, "uaa_file_id", uaaf.id)
    assert {:passed} = UAAP.validations(1, params, [])
  end
end
