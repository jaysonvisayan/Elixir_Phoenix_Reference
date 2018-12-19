defmodule Innerpeace.PayorLink.Web.Api.V1.PractitionerControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase

  alias PayorLink.Guardian.Plug
  # alias Innerpeace.Db.Base.Api.PractitionerContext

  setup do
    user = insert(:user, username: "masteradmin", password: "P@ssw0rd")
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = PayorLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)

    {:ok, %{
      conn: conn,
      jwt: jwt
    }}
  end

 test "/practitioners returns json doctor object when parameters are valid", %{conn: conn, jwt: jwt} do
     practitioner = insert(:practitioner, birth_date: Ecto.Date.cast!("1997-01-30"), first_name: "Daniel Eduard", last_name: "Andal", middle_name: "Murao", prc_no: "1231231", suffix: "Dr", affiliated: "Yes")
    insert(:bank, practitioner: practitioner)
    contact = insert(:contact)
    insert(:phone, contact: contact)
    insert(:email, contact: contact)
    account_group = insert(:account_group)
    facility = insert(:facility)
    specialization = insert(:specialization)
    insert(:practitioner_contact, contact: contact, practitioner: practitioner)
    insert(:practitioner_specialization, specialization: specialization, practitioner: practitioner)
    insert(:practitioner_facility, facility: facility, practitioner: practitioner)
    insert(:practitioner_account, account_group: account_group, practitioner: practitioner)
   conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")

    params = %{
      "first_name" => "Daniel Eduard",
      "middle_name" => "Murao",
      "last_name" => "Andal",
      "prc_no" => "1231231",
      "extension" => "Dr"
    }
    conn =
      conn
      |> post(api_practitioner_path(conn, :validate_affiliated_practitioner, params: params))
    assert json_response(conn, 200)
    assert json_response(conn, 200)["data"]["id"]
end

  test "/practitioners returns 404 when parameters are invalid", %{conn: conn, jwt: jwt} do
    practitioner = insert(:practitioner, birth_date: Ecto.Date.cast!("1997-01-30"), first_name: "Daniel Eduard", last_name: "Andal", middle_name: "Murao", prc_no: "1231231", suffix: "Dr", affiliated: "Yes")
    insert(:bank, practitioner: practitioner)
    contact = insert(:contact)
    insert(:phone, contact: contact)
    insert(:email, contact: contact)
    account_group = insert(:account_group)
    facility = insert(:facility)
    specialization = insert(:specialization)
    insert(:practitioner_contact, contact: contact, practitioner: practitioner)
    insert(:practitioner_specialization, specialization: specialization, practitioner: practitioner)
    insert(:practitioner_facility, facility: facility, practitioner: practitioner)
    insert(:practitioner_account, account_group: account_group, practitioner: practitioner)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
    params = %{
      "first_name" => "Jayson",
      "last_name" => "Visayan",
      "middle_name" => "Derulo"
    }
    conn =
      conn
      |> post(api_practitioner_path(conn, :validate_affiliated_practitioner, params: params))
    assert conn.status == 404
    assert json_response(conn, 404)["error"]
  end

  test "get /practitioners without parameters returns all practitioners", %{conn: conn, jwt: jwt} do
    practitioner = insert(:practitioner, birth_date: Ecto.Date.cast!("1997-01-30"), first_name: "Daniel Eduard", last_name: "Andal", middle_name: "Murao", prc_no: "1231231", suffix: "Dr", affiliated: "Yes")
    insert(:bank, practitioner: practitioner)
    contact = insert(:contact)
    insert(:phone, contact: contact)
    insert(:email, contact: contact)
    account_group = insert(:account_group)
    facility = insert(:facility)
    specialization = insert(:specialization)
    insert(:practitioner_contact, contact: contact, practitioner: practitioner)
    insert(:practitioner_specialization, specialization: specialization, practitioner: practitioner)
    insert(:practitioner_facility, facility: facility, practitioner: practitioner)
    insert(:practitioner_account, account_group: account_group, practitioner: practitioner)
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")

    conn =
      conn
      |> get(api_practitioner_path(conn, :index))
    assert json_response(conn, 200)
    refute Enum.empty?(json_response(conn, 200)["data"])
  end

  ### for POST API Practitioner/new
  # jose valim's comment
  #     we don't know how to encode a list with maps with less or more than one element inside. So we should
  #     raise whenever there is a map in a list and the number of elements in the map is different than 1.

  #  test "create practitioner returns practitioner struct when params are valid using payment_type = check", %{jwt: jwt} do
  #    specialization1 = insert(:specialization, name: "Radiology")
  #    specialization2 = insert(:specialization, name: "Dermatology")
  #    specialization3 = insert(:specialization, name: "Psychiatry")
  #    dropdown_affiliated = insert(:dropdown, type: "Practitioner Status", text: "Affiliated", value: "Affiliated")
  #    dropdown_medical_indication = insert(:dropdown, type: "CP Clearance", text: "Medical Indication", value: "Medical Indication")
  #    facility_calamba = insert(:facility, name: "Calamba Medical Center", code: "880000000000359")
  #
  #    params = %{
  #      "code" => "PRA-111111",
  #      "first_name" => "joseph",
  #      "middle_name" => "agustin",
  #      "last_name" => "canilao",
  #      "birth_date" => "1993-10-25",
  #      "suffix" => "a.",
  #      "gender" => "Male",
  #      "affiliated" => "Yes",
  #      "prc_no" => "312313213133",
  #      "status" => "Affiliated",
  #      "effectivity_from" => "2017-10-23",
  #      "effectivity_to" => "2017-10-23",
  #      "specialization_name" => "Psychiatry",
  #      "sub_specialization_name" => ["Radiology", "Dermatology"],
  #      "contact" => %{
  #        "email" => ["joseph_canilao@medilink.com.ph", "agustin.canilao@gmail.com"],
  #        "fax" => ["1339931"],
  #        "mobile_no" => ["09195608936", "09195608933"],
  #        "tel_no" => ["444-23-54"]
  #      },
  #      "exclusive" => ["PCS", "NON-PCS"],
  #      "prescription_period" => "te",
  #      "tin" => "442222333333",
  #      "withholding_tax" => "123",
  #      "vat_status" => "VAT-able",
  #      "payment_type" => "Check",
  #      "payee_name" => "Amerigo Vespucci",
  #      "practitioner_type" => ["Primary Care", "Specialist"],
  #      "facility_code" => "880000000000359",
  #      "pf_status" => "Affiliated",
  #      "affiliation_date" => "2017-10-30",
  #      "disaffiliation_date" => "2018-10-30",
  #      "payment_mode" => "Umbrella",
  #      "credit_term" => "1500",
  #      "pf_contact" => %{
  #        "email" => ["pf_joseph_canilao@calambamed.com.ph", "pf_agustin.canilao@calambamed.com.ph"],
  #        "fax" => ["4448855"],
  #        "mobile_no" => ["09195608955", "09366587799"],
  #        "tel_no" => ["333-99-44"]
  #      },
  #      "coordinator" => "true",
  #      "consultation_fee" => "1200.50",
  #      "coordinator_fee" => "4500.50",
  #      "cp_clearance_name" => "Medical Indication",
  #      "cp_clearance_rate" => "999.50",
  #      "fixed" => "true",
  #      "fixed_fee" => "7000.50",
  #      "schedule" => %{
  #       0 => %{
  #          "day" => "Monday",
  #          "time_from" => "12:00",
  #          "time_to" => "16:00",
  #          "room" => "Room1"
  #        }
  #      }
  #    }
  #
  #    conn =
  #      conn
  #      |> put_req_header("authorization", "Bearer #{jwt}")
  #      |> post(api_practitioner_path(conn, :create_practitioner_api, %{params: params}))
  #    assert json_response(conn, 200)
  #  end
  #
  #  test "create practitioner returns practitioner struct when params are valid using payment_type = bank", %{jwt: jwt} do
  #    specialization1 = insert(:specialization, name: "Radiology")
  #    specialization2 = insert(:specialization, name: "Dermatology")
  #    specialization3 = insert(:specialization, name: "Psychiatry")
  #    bank = insert(:bank, account_name: "Metropolitan Bank and Trust Company")
  #
  #    params = %{
  #      "code" => "PRA-111111",
  #      "first_name" => "joseph",
  #      "middle_name" => "agustin",
  #      "last_name" => "canilao",
  #      "birth_date" => "1993-10-25",
  #      "suffix" => "a.",
  #      "gender" => "Male",
  #      "affiliated" => "Yes",
  #      "prc_no" => "312313213133",
  #      "status" => "Affiliated",
  #      "effectivity_from" => "2017-10-23",
  #      "effectivity_to" => "2017-10-23",
  #      "specialization_name" => "Psychiatry",
  #      "sub_specialization_name" => ["Radiology", "Dermatology"],
  #      "contact" => %{
  #        "email" => ["joseph_canilao@medilink.com.ph", "agustin.canilao@gmail.com"],
  #        "fax" => ["1339931"],
  #        "mobile_no" => ["09195608936", "09195608933"],
  #        "tel_no" => ["444-23-54"]
  #      },
  #      "exclusive" => ["PCS", "NON-PCS"],
  #      "prescription_period" => "31",
  #      "tin" => "442222333333",
  #      "withholding_tax" => "50",
  #      "vat_status" => "VAT-able",
  #      "payment_type" => "Bank",
  #      "account_no" => "12313444",
  #      "bank_name" => "Metropolitan Bank and Trust Company"
  #    }
  #
  #    conn =
  #      conn
  #      |> put_req_header("authorization", "Bearer #{jwt}")
  #      |> post(api_practitioner_path(conn, :create_practitioner_api, %{params: params}))
  #    assert json_response(conn, 200)
  #  end
  #
  #  test "create practitioner returns practitioner struct when params are valid using payment_type = medilink xp card", %{jwt: jwt} do
  #    specialization1 = insert(:specialization, name: "Radiology")
  #    specialization2 = insert(:specialization, name: "Dermatology")
  #    specialization3 = insert(:specialization, name: "Psychiatry")
  #
  #    params = %{
  #      "code" => "PRA-111111",
  #      "first_name" => "joseph",
  #      "middle_name" => "agustin",
  #      "last_name" => "canilao",
  #      "birth_date" => "1993-10-25",
  #      "suffix" => "a.",
  #      "gender" => "Male",
  #      "affiliated" => "Yes",
  #      "prc_no" => "312313213133",
  #      "status" => "Affiliated",
  #      "effectivity_from" => "2017-10-23",
  #      "effectivity_to" => "2017-10-23",
  #      "specialization_name" => "Psychiatry",
  #      "sub_specialization_name" => ["Radiology", "Dermatology"],
  #      "contact" => %{
  #        "email" => ["joseph_canilao@medilink.com.ph", "agustin.canilao@gmail.com"],
  #        "fax" => ["1339931"],
  #        "mobile_no" => ["09195608936", "09195608933"],
  #        "tel_no" => ["444-23-54"]
  #      },
  #      "exclusive" => ["PCS", "NON-PCS"],
  #      "prescription_period" => "31",
  #      "tin" => "442222333333",
  #      "withholding_tax" => "50",
  #      "vat_status" => "VAT-able",
  #      "payment_type" => "MediLink XP Card",
  #      "xp_card_no" => "412414212421412"
  #    }
  #
  #    conn =
  #      conn
  #      |> put_req_header("authorization", "Bearer #{jwt}")
  #      |> post(api_practitioner_path(conn, :create_practitioner_api, %{params: params}))
  #    assert json_response(conn, 200)
  #  end

test "get_practitioner_by_vendor_code/2, get practitioner code by vendor code with valid parameter", %{conn: conn} do
  params = %{"vendor_code" => "123"}
  insert(:practitioner, vendor_code: "123", code: "123")

  conn =
    conn
    |> get(api_practitioner_path(conn, :get_practitioner_by_vendor_code, params))
  assert json_response(conn, 200) == render_json("vendor_code.json", code: "123")
end

test "get_practitioner_by_vendor_code/2, get practitioner code by vendor code with invalid parameter", %{conn: conn} do
  params = %{"vendor_code" => "345"}
  insert(:practitioner, vendor_code: "123", code: "1345423")

  conn =
    conn
    |> get(api_practitioner_path(conn, :get_practitioner_by_vendor_code, params))
  assert json_response(conn, 404) == render_json_error("error.json", message: "There was no practitioner having the given vendor code.")
end

test "get_practitioner_by_vendor_code/2, get practitioner code by vendor code with no parameter", %{conn: conn} do
  params = %{}
  insert(:practitioner, vendor_code: "123", code: "1345423")

  conn =
    conn
    |> get(api_practitioner_path(conn, :get_practitioner_by_vendor_code, params))
  assert json_response(conn, 404) == render_json_error("error.json", message: "Vendor code is empty.")
end

  defp render_json(template, assigns) do
    assigns = Map.new(assigns)

    template
    |> Innerpeace.PayorLink.Web.Api.V1.PractitionerView.render(assigns)
    |> Poison.encode!
    |> Poison.decode!
  end

  defp render_json_error(template, assigns) do
    assigns = Map.new(assigns)

    template
    |> Innerpeace.PayorLink.Web.ErrorView.render(assigns)
    |> Poison.encode!
    |> Poison.decode!
  end

end
