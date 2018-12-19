defmodule Innerpeace.PayorLink.Web.FacilityControllerTest do
  use Innerpeace.{
    PayorLink.Web.ConnCase
  }

  # import Innerpeace.PayorLink.TestHelper

  alias Ecto.UUID

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

  test "index renders form for index", %{conn: conn} do
    conn = get conn, facility_path(conn, :index)
    result = html_response(conn, 200)
    assert result =~ "Facility"
  end

  test "new renders form for new facility", %{conn: conn} do
    conn = get conn, facility_path(conn, :new)
    result = html_response(conn, 200)
    assert result =~ "Request Facility"
  end

  test "create_step1 creates facility and redirects to show data is valid", %{conn: conn, ftype: ftype, fcategory: fcategory, user: user} do
    params = %{
      name: "Test provider 1",
      license_name: "Test license name",
      ftype_id: ftype.id,
      fcategory_id: fcategory.id,
      loa_condition: "true",
      cutoff_time: "09:00:00",
      phic_accreditation_from: "02-02-2017",
      phic_accreditation_to: "02-02-2017",
      phic_accreditation_no: "1",
      status: "Affiliated",
      affiliation_date: "02-02-2017",
      step: 1,
      created_by_id: user.id,
      updated_by_id: user.id,
      code: "test code"
    }
    conn = post conn, facility_path(conn, :create_step1), facility: params
    %{id: id} = redirected_params(conn)

    result = redirected_to(conn)

    assert result == "/facilities/#{id}/setup?step=2"
  end

  test "create_step1 does not create facility and renders error when data is invalid", %{conn: conn, ftype: ftype, fcategory: fcategory, user: user} do
    params = %{
      name: "Test provider 1",
      license_name: "Test license name",
      ftype_id: ftype.id,
      fcategory_id: fcategory.id,
      loa_condition: "true",
      cutoff_time: "09:00:00",
      phic_accreditation_no: "1",
      status: "Affiliated",
      step: 1,
      created_by_id: user.id,
      updated_by_id: user.id
    }
    conn = post conn, facility_path(conn, :create_step1), facility: params

    result = get_flash(conn, :error)

    assert result =~ "Error creating facility!"
  end

  test "step1 renders form for update step 1 facility", %{conn: conn, facility: facility} do
    conn = get conn, facility_path(conn, :setup, facility.id, step: 1)
    result = html_response(conn, 200)

    assert result =~ "Philhealth Accreditation Number"
    assert result =~ "License Name"
    assert result =~ "Phone Number"
  end

  test "update_step1 updates step 1 facility and redirects to show data is valid", %{conn: conn,
    ftype: ftype, fcategory: fcategory, user: user, facility: facility}
  do
    params = %{
      name: "Test provider 1",
      license_name: "Test license name",
      ftype_id: ftype.id,
      fcategory_id: fcategory.id,
      loa_condition: "true",
      cutoff_time: "09:00:00",
      phic_accreditation_from: "07-07-2017",
      phic_accreditation_to: "07-07-2017",
      phic_accreditation_no: "1",
      status: "Affiliated",
      affiliation_date: "07-07-2017",
      step: 1,
      created_by_id: user.id,
      updated_by_id: user.id,
      code: "test code"
      }
    conn =
      conn
      |> put(
        facility_path(
          conn,
          :update_setup,
          facility,
          step: 1
        ),
        facility: params
      )
    result = redirected_to(conn)

    assert result == "/facilities/#{facility.id}/setup?step=2"
  end

  test "update_step1 does not update step 1 facility and renders error when data is invalid", %{conn: conn, facility: facility} do
    params = %{cutoff_time: "09:00:00"}
    conn =
      conn
      |> put(
        facility_path(
          conn,
          :update_setup,
          facility,
          step: 1
        ),
        facility: params
      )
    result = get_flash(conn, :error)

    assert result =~ "Error creating facility!"
  end

  test "step2 renders form for update step 2 facility", %{conn: conn, facility: facility} do
    conn = get conn, facility_path(conn, :setup, facility.id, step: 2)
    result = html_response(conn, 200)

    assert result =~ "City"
    assert result =~ "Country"
    assert result =~ "Province"
  end

  test "update_step2 updates step 2 facility and redirects to show data is valid", %{conn: conn, user: user, facility: facility} do
    location_group = insert(:location_group)

    params = %{
      line_1: "some contect",
      line_2: "some contect",
      city: "some contect",
      province: "some contect",
      region: "some contect",
      country: "some contect",
      postal_code: "some contect",
      latitude: "some contect",
      longitude: "some contect",
      step: 1,
      updated_by_id: user.id,
      location_group_ids: [location_group.id]
    }

    conn =
      conn
      |> put(
        facility_path(
          conn,
          :update_setup,
          facility,
          step: 2
        ),
        facility: params
      )

    result = redirected_to(conn)

    assert result == "/facilities/#{facility.id}/setup?step=3"
  end

  test "update_step2 does not update facility step 2 and render error when data is invalid", %{conn: conn, facility: facility} do
    params = %{
    }

    conn =
      conn
      |> put(
        facility_path(
          conn,
          :update_setup,
          facility,
          step: 2
        ),
        facility: params
      )
    result = get_flash(conn, :error)

    assert result =~ "Error creating facility!"
  end

  test "update_step2 does not update facility step 2 and render error when location group not exists", %{conn: conn, facility: facility, user: user} do
    params = %{
      line_1: "some contect",
      line_2: "some contect",
      city: "some contect",
      province: "some contect",
      region: "some contect",
      country: "some contect",
      postal_code: "some contect",
      latitude: "some contect",
      longitude: "some contect",
      step: 1,
      updated_by_id: user.id,
    }

    conn =
      conn
      |> put(
        facility_path(
          conn,
          :update_setup,
          facility,
          step: 2
        ),
        facility: params
      )
    result = html_response(conn, 200)

    assert result =~ "This is a required field"
  end

  test "update_step2 does not update facility step 2 and render error when longitude and latitude already in use", %{conn: conn, facility: facility, user: user} do
    location_group = insert(:location_group)

    :facility
    |> insert(
      longitude: "1233",
      latitude: "1213",
      code: "testcode",
      name: "testname",
      step: 7
    )

    params = %{
      line_1: "some contect",
      line_2: "some contect",
      city: "some contect",
      province: "some contect",
      region: "some contect",
      country: "some contect",
      postal_code: "some contect",
      latitude: "1213",
      longitude: "1233",
      step: 1,
      updated_by_id: user.id,
      location_group_ids: [location_group.id]
    }

    conn =
      conn
      |> put(
        facility_path(
          conn,
          :update_setup,
          facility,
          step: 2
        ),
        facility: params
      )
    result = html_response(conn, 200)

    assert result =~ "testcode testname is in the same location"
  end

  test "step3 renders form for update step 3 facility", %{conn: conn, facility: facility} do
    conn = get conn, facility_path(conn, :setup, facility.id, step: 3)
    result = html_response(conn, 200)

    assert result =~ "Telephone"
    assert result =~ "Mobile"
    assert result =~ "Fax"
  end

  test "create_contact creates facility contact and redirects to show data is valid", %{conn: conn, facility: facility} do
    params = %{
      last_name: "Test",
      first_name: "Test",
      department: "Test",
      designation: "Test",
      mobile: ["0912-121-21-21"],
      telephone: [""],
      fax: [""],
      email: "Janna_delacruz@medilink.com.ph"
    }

    conn =
      conn
      |> post(
        facility_path(conn, :create_contact, facility.id),
        facility: params
      )

    result = redirected_to(conn)

    assert result == "/facilities/#{facility.id}/setup?step=3"
  end

  test "create_contact does not create facility contact and renders error when data is invalid", %{conn: conn, facility: facility} do
    params = %{}
    conn =
     conn
     |> post(
       facility_path(
         conn,
         :create_contact,
         facility.id
       ),
       facility: params
     )
    result = get_flash(conn, :error)

    assert result =~ "Error creating contact!"
  end

  test "update_contact updates facility contact and redirects when data is valid", %{conn: conn, facility: facility} do
    contact = insert(:contact)
    params = %{
      last_name: "Test",
      first_name: "Test",
      department: "Test",
      designation: "Test",
      contact_id: contact.id,
      mobile: ["0912-121-21-21"],
      telephone: [""],
      fax: [""],
      email: "Janna_delacruz@medilink.com.ph"
    }

    conn =
      conn
      |> put(facility_path(conn, :update_contact, facility), facility: params)

    result = redirected_to(conn)

    assert result == "/facilities/#{facility.id}/setup?step=3"
  end

  test "next_contact redirects to next page", %{conn: conn, facility: facility} do
    conn = get conn, facility_path(conn, :next_contact, facility)
    result = redirected_to(conn)
    assert result == "/facilities/#{facility.id}/setup?step=4"
  end

  # test "get_contact", %{conn: conn, facility: facility} do

  # end

  # test "delete_facility_contact deletes chosen contact" do

  # end

  test "step4 renders form for update step 4 facility", %{conn: conn, facility: facility} do
    conn = get conn, facility_path(conn, :setup, facility.id, step: 4)
    result = html_response(conn, 200)

    assert result =~ "VAT Status"
    assert result =~ "Prescription Clause"
    assert result =~ "Credit Limit"
  end

  test "update_step4 updates step 4 facility and redirects to show data is valid", %{conn: conn, user: user, facility: facility} do
    params = %{
      tin: "test",
      step: 1,
      updated_by_id: user.id,
      prescription_term: "123",
      credit_term: "123",
      credit_limit: "123",
      balance_biller: true,
      withholding_tax: "123",
      authority_to_credit: true
    }
    conn =
      conn
      |> put(
        facility_path(conn, :update_setup, facility, step: 4),
        facility: params
      )

    result = redirected_to(conn)

    assert result == "/facilities/#{facility.id}/setup?step=5"
  end

  test "update_step4 does not update facility step 4 and render error when data is invalid", %{conn: conn, facility: facility} do
    params = %{}
    conn =
      conn
      |> put(
        facility_path(conn, :update_setup, facility, step: 4),
        facility: params
      )
    result = get_flash(conn, :error)

    assert result =~ "Error creating facility!"
  end

  test "step5 renders form for update step 5 facility", %{conn: conn, facility: facility} do
    conn = get conn, facility_path(conn, :setup, facility.id, step: 5)
    result = html_response(conn, 200)

    assert result =~ "Service Fee"
  end

  test "update_step5 updates step 5 facility and redirects to step 5", %{conn: conn, facility: facility} do
    service_type = insert(:dropdown, text: "Fixed Fee", value: "Fixed Fee")
    coverage = insert(:coverage)
    params = %{
      coverage_id: coverage.id,
      service_type_id: service_type.id,
      payment_mode: "Individual",
      rate: "123"
    }
    conn =
      conn
      |> post(
        facility_path(
          conn,
          :update_setup,
          facility,
          step: 5
        ),
        facility: params
      )
    result = redirected_to(conn)
    assert result == "/facilities/#{facility.id}/setup?step=5"
  end

  test "update_step5 does not update facility step 5 and render error when data is invalid", %{conn: conn, facility: facility} do
    params = %{
      service_type_id: UUID.generate()
    }
    conn =
      conn
      |> post(
        facility_path(conn, :update_setup, facility, step: 5),
        facility: params
      )
    result = get_flash(conn, :error)
    assert result =~ "Error adding facility service fee"
  end

  test "step6 renders form for update step 6 facility", %{conn: conn, facility: facility} do
    conn = get conn, facility_path(conn, :setup, facility.id, step: 6)
    result = html_response(conn, 200)

    assert result =~ "Name"
    assert result =~ "Billings"
    assert result =~ "PHIC"
  end

  # FacilityProcedure
  test "create facility procedure with valid attrs", %{conn: conn, facility: facility} do
    payor_procedure = insert(:payor_procedure)
    facility_room_rate = insert(:facility_room_rate)
    conn =
      conn
      |> post(
        facility_path(conn, :create_facility_payor_procedure, facility),
        facility_procedure: %{
          code: "Code",
          payor_procedure_id: payor_procedure.id,
          name: "Name",
          room_params: [
            facility_room_rate.id,
            1235,
            35,
            Ecto.Date.cast!("2017-08-10")
          ]
        }
      )

    result = redirected_to(conn)
    assert result == "/facilities/#{facility.id}?active=procedure"
  end

  test "create facility procedure with invalid attrs", %{conn: conn, facility: facility} do
    payor_procedure = insert(:payor_procedure)
    facility_room_rate = insert(:facility_room_rate)
    insert(:facility_payor_procedure, code: "Code")
    conn =
      conn
      |> post(
        facility_path(conn, :create_facility_payor_procedure, facility),
        facility_procedure: %{
          code: "Code",
          payor_procedure_id: payor_procedure.id,
          name: "Name",
          room_params: [
            facility_room_rate.id,
            1235,
            35,
            Ecto.Date.cast!("2017-08-10")
          ]
        }
      )
    result = redirected_to(conn)
    assert result == "/facilities/#{facility.id}?active=procedure"
  end

  test "Update facility procedure with valid attrs", %{conn: conn, facility: facility} do
    payor_procedure = insert(:payor_procedure)
    facility_payor_procedure =
      :facility_payor_procedure
      |> insert(payor_procedure: payor_procedure, facility: facility)
    facility_room_rate = insert(:facility_room_rate)
    facility_payor_procedure_room =
      :facility_payor_procedure_room
      |> insert(
        facility_payor_procedure: facility_payor_procedure,
        facility_room_rate: facility_room_rate
      )
    conn =
      conn
      |> put(
        facility_path(conn, :update_facility_payor_procedure, facility),
        facility_procedure: %{
          code: "Code",
          facility_payor_procedure_id: facility_payor_procedure.id,
          payor_procedure_id: payor_procedure.id,
          name: "Name",
          facility_payor_procedure_room_id: facility_payor_procedure_room.id,
          room_params: [
            facility_room_rate.id,
            1235,
            35,
            Ecto.Date.cast!("2017-08-10")]
        }
      )

    result = redirected_to(conn)
    assert result == "/facilities/#{facility.id}?active=procedure"
  end

  test "Update facility procedure with invalid attrs", %{conn: conn, facility: facility} do
    payor_procedure = insert(:payor_procedure)
    facility_payor_procedure =
      :facility_payor_procedure
      |> insert(payor_procedure: payor_procedure, facility: facility)
    facility_room_rate = insert(:facility_room_rate)
    facility_payor_procedure_room =
      :facility_payor_procedure_room
      |> insert(
        facility_payor_procedure: facility_payor_procedure,
        facility_room_rate: facility_room_rate
      )
    conn =
      conn
      |> put(
        facility_path(conn, :update_facility_payor_procedure, facility),
        facility_procedure: %{
          facility_payor_procedure_id: facility_payor_procedure.id,
          payor_procedure_id: payor_procedure.id,
          facility_payor_procedure_room_id: facility_payor_procedure_room.id,
          room_params: [
            facility_room_rate.id,
            1235,
            35,
            Ecto.Date.cast!("2017-08-10")
          ]
        }
      )

    result = redirected_to(conn)
    assert result == "/facilities/#{facility.id}?active=procedure"
  end

  # test "print_summary renders pdf with valid facility id", %{conn: conn} do
  #   facility = insert(:facility)
  #   phones = insert(:phone)
  #   emails = insert(:email)
  #   contact = [insert(:contact, phones: [phones], emails: [emails])]
  #   # fc = insert(:facility_contact, facility: facility, contact: contact)

  #   conn = get conn, facility_path(conn, :print_summary, facility.id)

  #   result = json_response(conn, 200)

  #   raise result
  #   raise result

  #   assert
  # end

  # test "print_summary redirects when invalid facility id", %{conn: conn} do
  #   facility = insert(:facility)
  #   conn = get conn, facility_path(conn, :print_summary, facility.id)

  #   result = redirected_to(conn)

  #   raise result

  #   assert
  # end

  test "new renders form for new import payor procedure", %{conn: conn, facility: facility} do
    conn = get conn, facility_path(conn, :new_import, facility)
    result = html_response(conn, 200)
    assert result =~ "Import Payor Procedures"
  end

  test "Import Payor Procedure batch no params returns error message", %{conn: conn, facility: facility} do
    conn =
      conn
      |> post(
        facility_path(
          conn,
          :import_facility_payor_procedure,
          facility.id
        )
      )

    assert conn.private[:phoenix_flash]["error"] =~ "Please upload a file."
    assert redirected_to(conn) ==
      "/facilities/payor_procedure/#{facility.id}/import"
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

  test "render_facility_payor_procedure return add facility payor procedure page", %{conn: conn, facility: facility} do
    conn =
      conn
      |> get(facility_path(conn, :render_facility_payor_procedure, facility))
    result = html_response(conn, 200)

    assert result =~ "Add Procedure"
  end

# Facility RUV
  test "create facility RUV with valid attrs", %{conn: conn} do
    ruv = insert(:ruv)
    facility = insert(:facility)
    conn =
      conn
      |> post(
        facility_path(conn, :create_ruv, facility),
        facility_ruv: %{
          ruv_id: ruv.id,
          facility_id: facility.id,
          effectivity_date: "23/02/2018"
        }
      )

    result = redirected_to(conn)
    assert result == "/facilities/#{facility.id}?active=ruv"
  end

  test "new renders form for new import ruv", %{conn: conn, facility: facility} do
    conn = get conn, facility_path(conn, :ruv_import, facility)
    result = html_response(conn, 200)
    assert result =~ "Import RUVs"
  end

  test "Import RUV batch no params returns error message", %{conn: conn, facility: facility} do
    conn = post conn, facility_path(conn, :import_facility_ruv, facility.id)

    assert conn.private[:phoenix_flash]["error"] =~ "Please upload a file."
    assert redirected_to(conn) == "/facilities/ruv/#{facility.id}/import"
  end

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

  test "get_location_group_by_region with return", %{conn: conn} do
    location_group =
      :location_group
      |> insert(
        step: "4",
        name: "Group Test"
      )

    :location_group_region
    |> insert(
      location_group: location_group,
      region_name: "NCR"
    )

    conn =
      conn
      |> get(facility_path(conn, :get_location_group_by_region, "NCR"))

    result = json_response(conn, 200)

    assert result ==
      Poison.encode!([%{
        name: "Group Test",
        id: location_group.id
      }])
  end

  test "get_location_group_by_region without return", %{conn: conn} do
    location_group =
      :location_group
      |> insert(
        step: "4",
        name: "Group Test"
      )

    :location_group_region
    |> insert(
      location_group: location_group,
      region_name: "NCR"
    )

    conn =
      conn
      |> get(facility_path(conn, :get_location_group_by_region, "Calabarzon"))

    result = json_response(conn, 200)

    assert result == Poison.encode!([])
  end

  test "delete facility draft deletes facility with valid id", %{conn: conn, facility: facility} do
    location_group =
      :location_group
      |> insert(
        step: "4",
        name: "Group Test"
      )

    contact =
      :contact
      |> insert()

    :facility_location_group
    |> insert(
      location_group: location_group,
      facility: facility
    )

    :facility_contact
    |> insert(
      contact: contact,
      facility: facility
    )

    conn =
      conn
      |> get(
        facility_path(
          conn,
          :delete_facility,
          facility
        )
      )

    result =
      conn
      |> get_flash(:info)

    assert result == "Facility deleted successfully."
  end

  test "delete facility draft returns error if invalid id", %{conn: conn} do
    conn =
      conn
      |> get(
        facility_path(
          conn,
          :delete_facility,
          UUID.generate()
        )
      )

    result =
      conn
      |> get_flash(:error)

    assert result == "Facility id does not exists."
  end


  test "edit facility, redirect to show page when valid params", %{conn: conn} do
    facility = insert(:facility)

    params = %{
      "id" => facility.id
    }
    conn = put conn, facility_path(conn, :edit_setup, facility, tab: "general", facility: params)

    assert html_response(conn, 200) =~ "Facility"
  end

  test "edit facility, redirect to show page when invalid params", %{conn: conn} do
    facility = insert(:facility)

    conn = get conn, facility_path(conn, :edit_setup, facility, id: facility.id)
    assert redirected_to(conn) == "/facilities/#{facility.id}?active=profile"
  end
end
