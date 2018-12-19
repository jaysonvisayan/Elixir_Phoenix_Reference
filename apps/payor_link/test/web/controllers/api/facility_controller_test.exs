defmodule Innerpeace.PayorLink.Web.Api.FacilityControllerTest do
  use Innerpeace.{
    PayorLink.Web.ConnCase
  }

  # import Innerpeace.PayorLink.TestHelper

  # alias Ecto.UUID

  setup do
    conn = build_conn()

    user = fixture(:user_permission, %{keyword: "manage_facilities", module: "Facilities"})
    conn = authenticated(conn, user)

    ftype =
      insert(:dropdown,
             type: "Facility Type",
             text: "HOSPITAL",
             value: "HOSPITAL")

    fcategory =
      insert(:dropdown,
             type: "Facility Category",
             text: "TERTIARY",
             value: "TERTIARY")

    # user =
    #   insert(:user, is_admin: true)

    facility =
      insert(:facility,
             name: "Test provider 1",
             license_name: "test license",
             type: ftype,
             category: fcategory,
             phic_accreditation_no: "1",
             status: "Affiliated",
             affiliation_date: Ecto.Date.utc,
             disaffiliation_date: Ecto.Date.utc,
             status: "Affiliated",
             step: 6,
             created_by: user,
             updated_by: user
      )

    # conn = sign_in(conn, user)
    {:ok, %{
      conn: conn,
      user: user,
      ftype: ftype,
      fcategory: fcategory,
      facility: facility
    }}
  end

  test "facility show export csv for facility_payor_procedure", %{conn: conn} do
    facility = insert(:facility)
    insert(:facility_payor_procedure, facility: facility, name: "fpp")
    params = %{
      "search_value" => "fpp"
    }
    conn =
      conn
      |> get(
        api_facility_path(conn, :download_fpp, facility),
        fpp_param: params
      )

    assert response_content_type(conn, :json) =~ "charset=utf-8"

  end

  test "facility show export csv for facility_payor_procedure batch success and fail", %{conn: conn} do
    facility = insert(:facility)
    facility_payor_procedure_upload_file =
      insert(:facility_payor_procedure_upload_file)

    insert(:facility_payor_procedure_upload_log,
           facility_payor_procedure_upload_file:
             facility_payor_procedure_upload_file,
           status: "success",
           room_code: "Testroom",
           start_date: Ecto.Date.cast!("2017-10-04"),
           remarks: "ok",
           discount: Decimal.new(100.55),
           amount: 1200.55,
           provider_cpt_code: "CMC101",
           provider_cpt_name: "CMCfpp",
           payor_cpt_code: "PYOR101",
           payor_cpt_name: "PYORpp"
    )
    conn =
      conn
      |> get(api_facility_path(conn, :fpp_batch_download, facility, "success"))
    assert response_content_type(conn, :json) =~ "charset=utf-8"

  end

# Facility RUV
  test "facility show export csv for facility_ruv", %{conn: conn} do
    facility = insert(:facility)
    ruv = insert(:ruv)
    insert(:facility_ruv, facility: facility, ruv: ruv)
    params = %{
      "search_value" => "fr"
    }
    conn =
      conn
      |> get(api_facility_path(conn, :download_fr, facility), fr_param: params)
    assert response_content_type(conn, :json) =~ "charset=utf-8"

  end

  test "facility show export csv for facility_ruv batch success and fail", %{conn: conn} do
    facility = insert(:facility)
    facility_ruv_upload_file = insert(:facility_ruv_upload_file)
    insert(:facility_ruv_upload_log,
           facility_ruv_upload_file: facility_ruv_upload_file,
           status: "success",
           effectivity_date: Ecto.Date.cast!("2017-10-04"),
           remarks: "ok",
           value: Decimal.new(10),
           ruv_code: "ruv_code",
           ruv_description: "ruv_description"
    )
    conn =
      conn
      |> get(api_facility_path(conn, :fr_batch_download, facility, "success"))
    assert response_content_type(conn, :json) =~ "charset=utf-8"
  end
end
