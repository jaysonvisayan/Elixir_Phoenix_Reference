defmodule Innerpeace.PayorLink.Web.Api.V1.Vendor.PractitionerControllerTest do
    @moduledoc false

    use Innerpeace.PayorLink.Web.ConnCase

    alias PayorLink.Guardian.Plug

  setup do
    user = insert(:user, username: "masteradmin", password: "P@ssw0rd")
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = PayorLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = Plug.current_token(conn)

    facility =
      insert(
        :facility,
        code: "cmc",
        name: "CALAMBA MEDICAL CENTER",
        status: "Affiliated",
        affiliation_date: "2017-11-10",
        disaffiliation_date: "2018-11-23"
      )

    practitioner =
      insert(
        :practitioner,
        first_name: "Daniel",
        middle_name: "Murao",
        last_name: "Andal",
        code: "prac123",
        affiliated: "Yes",
        effectivity_from: "2017-11-13",
        effectivity_to: "2019-11-13"
      )

    practitioner_facility =
      insert(
        :practitioner_facility,
        affiliation_date: "2017-11-10",
        disaffiliation_date: "2018-11-17",
        payment_mode: "Umbrella",
        coordinator: true,
        consultation_fee: 400,
        cp_clearance_rate: 400,
        fixed: true,
        fixed_fee: 400,
        coordinator_fee: 400,
        facility_id: facility.id,
        practitioner_id: practitioner.id
      )

    specialization =
      insert(
        :specialization,
        name: "Anesthesiology"
      )

    insert(
      :practitioner_specialization,
      type: "Primary",
      specialization_id: specialization.id,
      practitioner_id: practitioner.id
    )

    {:ok, %{practitioner_facility: practitioner_facility, jwt: jwt, facility: facility, practitioner: practitioner}}
  end

    test "get_accredited_verification/2, returns if a practitioner is accredited with valid parameter", %{conn: conn, jwt: jwt} do
      params = %{
        "practitioner_code" => "prac123"
      }

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{jwt}")
        |> post(api_vendor_practitioner_path(conn, :get_accredited_verification, params))

      assert json_response(conn, 200)
    end

    test "get_affiliated_verification/2, returns if a practitioner is accredited with invalid parameter", %{conn: conn, jwt: jwt} do
      params = %{}

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{jwt}")
        |> post(api_vendor_practitioner_path(conn, :get_affiliated_verification, params))

      assert json_response(conn, 400)
    end

    test "get_affiliated_verification/2, returns if a practitioner is accredited with valid parameter", %{conn: conn, jwt: jwt} do
      params = %{
        "practitioner_code" => "prac123",
        "facility_code" => "cmc"
      }

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{jwt}")
        |> post(api_vendor_practitioner_path(conn, :get_affiliated_verification, params))

      assert json_response(conn, 200)
    end

    test "get_practitioner/2, returns all practitioner with parameters", %{conn: conn, jwt: jwt} do
      params = %{
        "practitioner_code" => "prac123"
      }

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{jwt}")
        |> post(api_vendor_practitioner_path(conn, :get_practitioner, params))

      assert json_response(conn,200)
    end

    test "get_practitioner/2, returns all practitioner without parameters", %{conn: conn, jwt: jwt} do
      params = %{
      }

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{jwt}")
        |> post(api_vendor_practitioner_path(conn, :get_practitioner, params))

      assert json_response(conn, 200)
    end
  end
