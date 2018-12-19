defmodule Innerpeace.PayorLink.Web.Api.V1.Vendor.FacilityControllerTest do
  @moduledoc false

  use Innerpeace.PayorLink.Web.ConnCase

  alias PayorLink.Guardian.Plug
  alias Decimal

  setup do
    user = insert(:user, username: "masteradmin", password: "P@ssw0rd")
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = PayorLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)

    dropdown =
      insert(:dropdown,
        type: "Facility Type",
        text: "HOSPITAL-BASED",
        value: "HB"
      )

    facility =
      insert(
        :facility,
        type: dropdown,
        code: "cmc",
        name: "CALAMBA MEDICAL CENTER",
        status: "Affiliated",
        affiliation_date: "2017-11-10",
        disaffiliation_date: "2018-11-23",
        city: "Makati",
        step: 7
      )

    {:ok, %{facility: facility, jwt: jwt, conn: conn}}
  end

  test "index, get /vendor/facility by code or name with affiliated practitioner with valid parameters", %{conn: conn, facility: facility, jwt: jwt} do
    practitioner =
      insert(
        :practitioner,
        code: "PRA-0001",
        first_name: "Test Practitioner",
        middle_name: "T",
        last_name: "Test",
        status: "Affiliated",
        suffix: "Dr"
      )

    insert(
      :practitioner_facility,
      facility: facility,
      practitioner: practitioner,
      affiliation_date: Ecto.Date.cast!("2018-04-07"),
      disaffiliation_date: Ecto.Date.cast!("2018-04-07"),
      payment_mode: "Bank",
      credit_term: 2,
      coordinator: true,
      consultation_fee: Decimal.new(1),
      coordinator_fee: Decimal.new(1),
      cp_clearance_rate: Decimal.new(1),
      fixed: true,
      fixed_fee: Decimal.new(1),
      step: 5
    )

    params = %{"facility" => "CALAMBA MEDICAL CENTER"}
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_vendor_facility_path(conn, :index, params))
    assert json_response(conn, 200)
    assert json_response(conn, 200)["data"]
  end

  test "index, get /vendor/facility by code or name without affiliated practitioner with valid parameters", %{conn: conn, jwt: jwt} do
    params = %{"facility" => "CALAMBA MEDICAL CENTER"}
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_vendor_facility_path(conn, :index, params))
    assert json_response(conn, 404)
    assert json_response(conn, 404) == %{"error" => %{"message" => "Facility does not have affiliated practitioner."}}
  end

  test "index, get /vendor/facility by code or name with invalid parameters", %{conn: conn, jwt: jwt} do
    params = %{"facility" => nil}
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_vendor_facility_path(conn, :index, params))

    assert json_response(conn, 404)
    assert json_response(conn, 404) == %{"error" => %{"message" => "Please input facility name or code."}}
  end

  test "search_facility_by_location, get /vendor/facility by code or name with valid parameters", %{conn: conn, jwt: jwt, facility: facility} do
    practitioner =
      insert(
        :practitioner,
        code: "PRA-0001",
        first_name: "Test Practitioner",
        middle_name: "T",
        last_name: "Test",
        status: "Affiliated",
        suffix: "Dr"
      )

    insert(
      :practitioner_facility,
      facility: facility,
      practitioner: practitioner,
      affiliation_date: Ecto.Date.cast!("2018-04-07"),
      disaffiliation_date: Ecto.Date.cast!("2018-04-07"),
      payment_mode: "Bank",
      credit_term: 2,
      coordinator: true,
      consultation_fee: Decimal.new(1),
      coordinator_fee: Decimal.new(1),
      cp_clearance_rate: Decimal.new(1),
      fixed: true,
      fixed_fee: Decimal.new(1),
      step: 5
    )

    params = %{"facility" => "Makati"}
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_vendor_facility_path(conn, :search_facility_by_location, params))

    assert json_response(conn, 200)
    assert json_response(conn, 200)["data"]
  end

  test "search_facility_by_location, get /vendor/facility by code or name with no practitioner found", %{conn: conn, jwt: jwt} do
    params = %{"facility" => "CALAMBA MEDICAL CENTER"}
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_vendor_facility_path(conn, :search_facility_by_location, params))
    assert json_response(conn, 404)
    assert json_response(conn, 404) == %{"error" => %{"message" => "Facility does not have affiliated practitioner."}}
  end

  test "search_facility_by_location, get /vendor/facility by code or name with invalid parameters", %{conn: conn, jwt: jwt} do
    params = %{"facility" => nil}
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> post(api_vendor_facility_path(conn, :search_facility_by_location, params))
    assert json_response(conn, 404)
    assert json_response(conn, 404) == %{"error" => %{"message" => "Please input facility location."}}
  end
end
