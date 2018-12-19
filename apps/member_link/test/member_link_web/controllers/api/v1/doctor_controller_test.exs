defmodule MemberLinkWeb.Api.V1.DoctorControllerTest do
  # use Innerpeace.Db.SchemaCase, async: true
  use MemberLinkWeb.ConnCase

  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    # Doctor,
    User
  }
  # alias Innerpeace.Db.Base.{
  #   DoctorContext
  # }

  setup do
    member = insert(:member, first_name: "Shane")
    {:ok, user} = Repo.insert(%User{username: "abbymae", password: "P@ssw0rd", member_id: member.id})
    random = Ecto.UUID.generate
    secure_random = "#{user.id}+#{random}"
    conn = MemberLink.Guardian.Plug.sign_in(build_conn(), secure_random)
    jwt = MemberLink.Guardian.Plug.current_token(conn)

    {:ok, %{user: user, conn: conn, jwt: jwt, member: member}}
  end

  test "search practitioner return practitioner", %{conn: conn, jwt: jwt, member: member} do
    practitioner = insert(:practitioner, first_name: "jayson",
                          middle_name: "binayug", last_name: "visayan", gender: "Male", status: "Affiliated")
    dropdown = insert(:dropdown, text: "HOSPITAL-BASED", type: "Facility Type", value: "HB")
    facility = insert(:facility, name: "General Hospital", code: "123", line_1: "123", line_2: "123", city: "123",  province: "123", region: "123", country: "123", postal_code: "123", step: 7, status: "Affiliated", type: dropdown)
    specialization = insert(:specialization, name: "Neurology")
    prac_fac = insert(:practitioner_facility,
           practitioner_id: practitioner.id,
           facility_id: facility.id)
    insert(:practitioner_specialization,
           practitioner_id: practitioner.id,
           specialization_id: specialization.id,
           type: "Primary")
    insert(:practitioner_schedule, practitioner_facility: prac_fac, day: "tuesday")
    contact = insert(:contact)
    insert(:phone, contact: contact)
    insert(:email, contact: contact)
    account = insert(:account)
    product = insert(:product)
    coverage = insert(:coverage)
    insert(:practitioner_contact, contact: contact, practitioner: practitioner)
    insert(:product_coverage, product: product, coverage: coverage, type: "exception")
    account_product = insert(:account_product, account: account, product: product)
    insert(:member_product, member: member, account_product: account_product)
    params = %{"name" => "jayson", "gender" => "male"}
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(doctor_path(conn, :search, params))
    assert json_response(conn, 200)
  end

 #test "search practitioner return Invalid Name when search name is invalid", %{conn: conn, jwt: jwt} do
 #  practitioner = insert(:practitioner, first_name: "jayson",
 #                        middle_name: "binayug", last_name: "visayan")
 #  facility = insert(:facility, name: "General Hospital")
 #  specialization = insert(:specialization, name: "Neurology")
 #  practitioner_facility = insert(:practitioner_facility,
 #                                 practitioner_id: practitioner.id,
 #                                 facility_id: facility.id)
 #  practitioner_specialization = insert(:practitioner_specialization,
 #                                       practitioner_id: practitioner.id,
 #                                       specialization_id: specialization.id,
 #                                       type: "Primary")
 #  params = %{"name" => ""}

 #  conn =
 #    conn
 #    |> put_req_header("authorization", "Bearer #{jwt}")
 #    |> get doctor_path(conn, :search, params)

 #  assert json_response(conn, 400)["message"] == "Invalid Name"
 #end

  test "search practitioner return No Doctors Found when Doctors not found", %{conn: conn, jwt: jwt, member: member} do
    practitioner = insert(:practitioner, first_name: "jayson",
                          middle_name: "binayug", last_name: "visayan", gender: "Male")
    facility = insert(:facility, name: "General Hospital")
    specialization = insert(:specialization, name: "Neurology")
    insert(:practitioner_facility,
           practitioner_id: practitioner.id,
           facility_id: facility.id)
    insert(:practitioner_specialization,
           practitioner_id: practitioner.id,
           specialization_id: specialization.id,
           type: "Primary")
    contact = insert(:contact)
    insert(:phone, contact: contact)
    insert(:email, contact: contact)
    account = insert(:account)
    product = insert(:product)
    coverage = insert(:coverage)
    insert(:practitioner_contact, contact: contact, practitioner: practitioner)
    product_coverage = insert(:product_coverage, product: product, coverage: coverage)
    insert(:product_coverage_facility, product_coverage: product_coverage, facility: facility)
    account_product = insert(:account_product, account: account, product: product)
    insert(:member_product, member: member, account_product: account_product)
    params = %{"name" => "sjdawsss", "gender" => "Male"}

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(doctor_path(conn, :search, params))

    assert json_response(conn, 404)["message"] == "No Doctors Found"
  end

  test "get_specializations returns list of specializations", %{conn: conn, jwt: jwt} do
    insert(:specialization, name: "Neurology")
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(doctor_path(conn, :get_specializations))

    assert json_response(conn, 200)
  end

  test "get_specializations returns 404 when no specialization are found", %{conn: conn, jwt: jwt} do
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(doctor_path(conn, :get_specializations))

    assert json_response(conn, 404)["message"] == "No Specializations Found"
  end
end
