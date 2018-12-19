defmodule Innerpeace.Db.Parsers.FacilityPayorProcedureParserTest do
  use Innerpeace.Db.SchemaCase, async: true
  alias Innerpeace.Db.{
    Repo,
    Schemas.FacilityPayorProcedure,
    Schemas.FacilityPayorProcedureUploadLog,
    Schemas.FacilityPayorProcedureRoom
  }
  alias Innerpeace.Db.Parsers.FacilityPayorProcedureParser, as: FPPP

  @valid_attrs %{
    "Amount" => "120",
    "Discount" => "100",
    "Effective Date" => " 10/06/2017 ",
    #"Payor CPT Name" => "(ACP) ACID PHOSPHATASE",
    "Facility CPT Code" => "ProvCPTCode-01",
    "Facility CPT Description" => "ProvCPTCode-Desc-01",
  }

  setup do
    user = insert(:user)
    facility = insert(:facility)
    room = insert(:room, code: "101")
    payor_procedure = insert(:payor_procedure, code: "S2196")
    facility_room_rate = insert(:facility_room_rate, facility: facility, room: room)
    facility_payor_procedure = insert(:facility_payor_procedure, facility: facility, payor_procedure: payor_procedure)

    {:ok, %{
      fpp: facility_payor_procedure,
      frr: facility_room_rate,
      user: user,
      facility: facility
    }}
  end

  test "Parse facility payor procedure returns success", %{facility: facility, user: user} do
    filename = "Test.csv"
    data = [{:ok, Map.merge(@valid_attrs, %{"Room Code" => "101", "Payor CPT Code" => "S2196"})}]

    _result = FPPP.parse_data(data, filename, facility.id, user.id)

    [_fpp] = Repo.all FacilityPayorProcedure
    [_fppr] = Repo.all FacilityPayorProcedureRoom
    [fppul] = Repo.all FacilityPayorProcedureUploadLog

    assert fppul.status == "success"
  end

  test "Parse facility payor procedure returns failed (Room code does not exist)", %{user: user, facility: facility} do
    filename = "Test.csv"
    data = [{:ok, Map.merge(@valid_attrs, %{"Room Code" => "102", "Payor CPT Code" => "S2196"})}]

    _result = FPPP.parse_data(data, filename, facility.id, user.id)
    [fppul] = Repo.all FacilityPayorProcedureUploadLog

    assert fppul.status == "failed"
    assert fppul.remarks == "Room Code is not mapped yet to the Facility."
  end

  test "Parse facility payor procedure returns failed (FacilityPayorProcedureRoom is already exist.)", %{fpp: fpp, facility: facility, user: user, frr: frr} do
    insert(:facility_payor_procedure_room, facility_payor_procedure: fpp, facility_room_rate: frr)

    filename = "Test.csv"
    data = [{:ok, Map.merge(@valid_attrs, %{"Room Code" => "101", "Payor CPT Code" => "S2196"})}]

    _result = FPPP.parse_data(data, filename, facility.id, user.id)
    [fppul] = Repo.all FacilityPayorProcedureUploadLog

    assert fppul.status == "failed"
    assert fppul.remarks == "Procedure already has a rate for this room type."
  end

  test "Parse facility payor procedure returns failed (Procedure does not exist.)", %{facility: facility, user: user} do
    filename = "Test.csv"
    data = [{:ok, Map.merge(@valid_attrs, %{"Room Code" => "101", "Payor CPT Code" => "S21961"})}]

    _result = FPPP.parse_data(data, filename, facility.id, user.id)
    [fppul] = Repo.all FacilityPayorProcedureUploadLog

    assert fppul.status == "failed"
    assert fppul.remarks == "Payor CPT code does not exist."
  end

  test "Parse facility payor procedure with existing facility payor procedure returns success.", %{fpp: fpp, facility: facility, user: user, frr: frr} do
    room = insert(:room, code: "1014")
    insert(:facility_room_rate, room: room, facility: facility)
    insert(:facility_payor_procedure_room, facility_payor_procedure: fpp, facility_room_rate: frr)

    filename = "Test.csv"
    data = [{:ok, Map.merge(@valid_attrs, %{"Room Code" => "1014", "Payor CPT Code" => "S2196"})}]

    _result = FPPP.parse_data(data, filename, facility.id, user.id)

    [_fpp] = Repo.all FacilityPayorProcedure
    [_fppr1, _fppr2] = Repo.all FacilityPayorProcedureRoom
    [fppul] = Repo.all FacilityPayorProcedureUploadLog

    assert fppul.status == "success"
  end

  test "Parse facility payor procedure returns Please enter column with emtpy fields", %{facility: facility, user: user} do
    data = [{:ok, Map.merge(@valid_attrs, %{"Room Code" => "", "Payor CPT Code" => ""})}]

    filename = "Test.csv"
    _result = FPPP.parse_data(data, filename, facility.id, user.id)
    [fppul] = Repo.all FacilityPayorProcedureUploadLog

    assert fppul.status == "failed"
    assert fppul.remarks == "Please enter Payor CPT Code, Please enter Room Code"
  end

  test "Parse facility payor procedure returns Discount must only be 1-100", %{facility: facility, user: user} do
    data = [{:ok,
      @valid_attrs
      |> Map.merge(%{"Room Code" => "1014", "Payor CPT Code" => "S2196"})
      |> Map.put("Discount", "120")
    }]

    filename = "Test.csv"
    _result = FPPP.parse_data(data, filename, facility.id, user.id)
    [fppul] = Repo.all FacilityPayorProcedureUploadLog

    assert fppul.status == "failed"
    assert fppul.remarks == "Discount must only be 1-100"
  end
end
