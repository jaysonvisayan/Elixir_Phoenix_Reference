defmodule Innerpeace.PayorLink.Web.Api.V1.FacilityControllerTest do
  use Innerpeace.PayorLink.Web.ConnCase

  alias PayorLink.Guardian.Plug
  setup do
    user = insert(:user, username: "masteradmin", password: "P@ssw0rd")
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = PayorLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)

    {:ok, %{conn: conn, jwt: jwt}}
  end

  # test "create facility returns facility struct when params are valid", %{jwt: jwt} do
    #    dropdown1 = insert(:dropdown, type: "VAT Status", text: "20% VAT-able", value: "20% VAT-able")
    #    dropdown2 = insert(:dropdown, type: "Prescription Clause", text: "No Provision", value: "No Provision")
    #    dropdown3 = insert(:dropdown, type: "Facility Type", text: "AMBULANCE", value: "A")
    #    dropdown4 = insert(:dropdown, type: "Facility Category", text: "TERTIARY", value: "TER")
    #
    #      x =%{
    #          "first_name" => "Contact Person",
    #          "last_name" => "Mr. Right",
    #          "department" => "string",
    #          "designation" => "string",
    #          "telephone" => ["1234567"],
    #          "mobile" => ["09184654213"],
    #          "email" => "account@yahoo.com"
    #      }
    #      y = %{
    #          "first_name" => "Contact Person",
    #          "last_name" => "Mr. Right",
    #          "department" => "string",
    #          "designation" => "string",
    #          "telephone" => ["1234567"],
    #          "mobile" => ["09184654213"],
    #          "email" => "account@yahoo.com"
    #      }
    #
    #    test333 = [%{
    #      testing: x,
    #      testing2: y
    #    }]
    #
    #    params = %{
    #      "code" => "SAMPLE CODE 4",
    #      "name" => "SAMPLE NAME 3",
    #      "type" => "Platinum",
    #      "facility_type" => "AMBULANCE",
    #      "facility_category" => "TERTIARY",
    #      "license_name" => "MBL",
    #      "phic_accreditation_from" => "2017-08-01",
    #      "phic_accreditation_to" => "2017-09-01",
    #      "phic_accreditation_no" => "12345678910",
    #      "status" => "Affiliated",
    #      "affiliation_date" => "2017-11-01",
    #      "disaffiliation_date" => "2017-11-01",
    #      "phone_no" => "4050081",
    #      "email_address" => "www@yahoo.com",
    #      "website" => "www@yahoo.com",
    #      "line_1" => "514 Quezon Boulevard",
    #      "line_2" => "Quiapo",
    #      "city" => "Manila",
    #      "province" => "Metro Manila",
    #      "region" => "NCR",
    #      "country" => "Philippines",
    #      "postal_code" => "4232",
    #      "longitude" => "120.98447220000003",
    #      "latitude" => "14.5996716",
    #      "tin" => "123123123123",
    #      "vat_status" => "20% VAT-able",
    #      "prescription_clause" => "No Provision",
    #      "prescription_term" => "1",
    #      "credit_term" => "1",
    #      "credit_limit" => "1",
    #      "no_of_beds" => "2",
    #      "bond" => "1",
    #      "payee_name" => "Mr Right",
    #      "withholding_tax" => "1111111111111111111",
    #      "bank_account_no" => "111111111111111111111",
    #      "balance_biller" => false,
    #      "authority_to_credit" => true,
    #      "mode_of_payment" => "Bank",
    #      "mode_of_releasing" => "ADA",
    #      "contact" => [x, y]
    #    }
    #
    #    conn =
    #      conn
    #      |> put_req_header("authorization", "Bearer #{jwt}")
    #      |> post(api_facility_path(conn, :create_facility_api, %{params: params}))
    #    assert json_response(conn, 200)
  # end

  test "get_facility_by_vendor_code/2, get facility code by vendor code with valid parameters", %{conn: conn} do
    params = %{"vendor_code" => "123"}
    insert(:facility, vendor_code: "123", code: "123")
    conn =
      conn
      |> get(api_facility_path(conn, :get_facility_by_vendor_code, params))
    assert json_response(conn, 200) == render_json("vendor_code.json", code: "123")
  end

  test "get_facility_by_vendor_code/2, get facility code by vendor code with invalid parameters", %{conn: conn} do
    params = %{"vendor_code" => "34"}
    insert(:facility, vendor_code: "123")

    conn =
      conn
      |> get(api_facility_path(conn, :get_facility_by_vendor_code, params))
    assert json_response(conn, 404) == render_json_error("error.json", message: "There was no facility having the given vendor code.")
  end

  test "get_facility_by_vendor_code/2, get facility code by vendor code with no parameters",  %{conn: conn} do
    params = %{}
    insert(:facility, vendor_code: "123")

    conn =
      conn
      |> get(api_facility_path(conn, :get_facility_by_vendor_code, params))
    assert json_response(conn, 404) == render_json_error("error.json", message: "Vendor code is empty.")
  end

  test "get facility by code success", %{conn: conn, jwt: jwt} do
    insert(:facility, code: "code-101")
    params = %{code: "code-101"}
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(api_facility_path(conn, :get_facility_by_code, params))
    assert json_response(conn, 200)["code"] == "code-101"
  end

  test "get facility by code", %{conn: conn, jwt: jwt} do
    params = %{code: "code-101"}
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(api_facility_path(conn, :get_facility_by_code, params))
    assert json_response(conn, 404)["error"]["message"] == "Facility not found"
  end

  defp render_json(template, assigns) do
    assigns = Map.new(assigns)

    template
    |> Innerpeace.PayorLink.Web.Api.V1.FacilityView.render(assigns)
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

