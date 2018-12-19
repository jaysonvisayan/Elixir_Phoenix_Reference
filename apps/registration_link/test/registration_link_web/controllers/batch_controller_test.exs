defmodule RegistrationLinkWeb.BatchControllerTest do
  use RegistrationLinkWeb.ConnCase
  use Innerpeace.Db.SchemaCase, async: true

  alias RegistrationLink.Guardian.Plug
  alias Innerpeace.Db.Repo
  alias Innerpeace.Db.Schemas.{
    User
  }

  setup do
    {:ok, user} = Repo.insert(%User{username: "test_user", password: "P@ssw0rd"})
    conn = Plug.sign_in(build_conn(), user)
    coverage = insert(:coverage,
                      name: "OP Consult",
                      description: "OP Consult",
                      code: "OPC",
                      type: "A",
                      status: "A",
                      plan_type: "health_plans")
    account_group = insert(:account_group, name: "ACCOUNT101", code: "ACC101")
    member = insert(:member, %{
      first_name: "Daniel Eduard",
      last_name: "Andal",
      card_no: "123456789012",
      account_group: account_group,
      account_code: account_group.code,
      status: "Active"
    })
    facility = insert(:facility, status: "Affiliated")
    authorization = insert(:authorization,
                           coverage: coverage,
                           member: member,
                           facility: facility)
    {:ok, %{conn: conn, user: user, authorization: authorization}}
  end

  # test "create_batch returns success with valid attrs", %{conn: conn, user: user} do
  #  f = insert(:facility, name: "1", status: "Affiliated", step: 7)
  #   params = %{
  #     "facility_id" => f.id,
  #     "type" => "hb",
  #     "soa_fef_no" => "123",
  #     "soa_amount" => "456",
  #     "estimate_no_of_claims" => "10",
  #     "date_received" => "2017-01-01",
  #     "date_due" => "2017-02-01",
  #     "mode_of_receiving" => "Mode1"
  #   }

  #   conn = post conn, batch_path(conn, :create_hb_batch), batch: params, data: [], facility: [{f.name, f.id}]
  #   assert html_response(conn, 200) =~ "Batch Processing"
  # end

  # test "create_pf_batch returns success with valid attrs", %{conn: conn} do
  #  f = insert(:facility, name: "1", status: "Affiliated", step: 7)
  #  p = insert(:practitioner, first_name: "test", last_name: "test")
  #   params = %{
  #     "facility_id" => f.id,
  #     "practitioner_id" => p.id,
  #     "type" => "hb",
  #     "soa_ref_no" => "123",
  #     "soa_amount" => "456",
  #     "estimate_no_of_claims" => "10",
  #     "date_received" => "2017-01-01",
  #     "date_due" => "2017-02-01",
  #     "mode_of_receiving" => "Mode1"
  #   }

  #   conn = post conn, batch_path(conn, :create_pf_batch), batch: params, data: [], facility: [{f.name, f.id}]

  #   assert html_response(conn, 200) =~ "Create PF Batch"
  # end

  # test "update_pf_batch returns error with invalid attrs", %{conn: conn} do
    # f = insert(:facility, name: "1", status: "Affiliated", step: 7)
    # p = insert(:practitioner, first_name: "test", last_name: "test")

    # batch = insert(
    #   :batch,
    #   batch_no: "Batch-101",
    #   facility_id: f.id,
    #   practitioner_id: p.id,
    #   type: "PF",
    #   soa_ref_no: "HB23",
    #   soa_amount: "25",
    #   estimate_no_of_claims: "25",
    #   date_received: "2017-01-01",
    #   date_due: "2017-02-01",
    #   mode_of_receiving: "mode1",
    #   coverage: "Outpatient"
    # )

    # params = %{
    #   "facility_id" => "",
    #   "practitioner_id" => "",
    #   "soa_fef_no" => "123",
    #   "soa_amount" => "456",
    #   "estimate_no_of_claims" => "10",
    #   "date_received" => "2017-01-01",
    #   "date_due" => "2017-02-01",
    #   "mode_of_receiving" => "mode2",
    #   "coverage" => "Outpatient"
    # }

    # conn = put(conn, batch_path(conn, :update_pf_batch, batch), batch: params, data: [], facility: [{f.name, f.id}])
    # assert html_response(conn, 200) =~ "Update PF Batch"
    # assert html_response(conn, 200) =~ batch.batch_no
    # assert html_response(conn, 200) =~ batch.facility_id
    # assert html_response(conn, 200) =~ batch.practitioner_id
    # assert html_response(conn, 200) =~ batch.coverage
    # assert html_response(conn, 200) =~ batch.mode_of_receiving
  # end
  # test "render edit pf batch", %{conn: conn} do
  #   f = insert(:facility, name: "1", status: "Affiliated", step: 7)
  #   p = insert(:practitioner, first_name: "test", last_name: "test")
  #   batch = insert(
  #     :batch,
  #     facility_id: f.id,
  #     practitioner_id: p.id,
  #     type: "HB",
  #     soa_ref_no: "HB23",
  #     soa_amount: "25",
  #     estimate_no_of_claims: "25",
  #     date_received: "2017-01-01",
  #     date_due: "2017-02-01",
  #     mode_of_receiving: "mode1",
  #     batch_no: "Batch-101"
  #   )
  #   conn = get conn, batch_path(conn, :edit_pf_batch, batch)
  #   assert html_response(conn, 200) =~ "Update PF Batch"
  # end

  # test "update_pf_batch returns success with valid attrs", %{conn: conn} do
  #   f = insert(:facility, name: "1", status: "Affiliated", step: 7)
  #   p = insert(:practitioner, first_name: "test", last_name: "test")

  #   batch = insert(
  #     :batch,
  #     batch_no: "Batch-101",
  #     facility_id: f.id,
  #     practitioner_id: p.id,
  #     type: "PF",
  #     soa_ref_no: "HB23",
  #     soa_amount: "25",
  #     estimate_no_of_claims: "25",
  #     date_received: "2017-01-01",
  #     date_due: "2017-02-01",
  #     mode_of_receiving: "mode1",
  #     coverage: "Outpatient"
  #   )

  #   params = %{
  #     "facility_id" => f.id,
  #     "practitioner_id" => p.id,
  #     "soa_fef_no" => "123",
  #     "soa_amount" => "456",
  #     "estimate_no_of_claims" => "10",
  #     "date_received" => "2017-01-01",
  #     "date_due" => "2017-02-01",
  #     "mode_of_receiving" => "mode2",
  #     "coverage" => "Outpatien"
  #   }

  # test "update_hb_batch returns error with invalid attrs", %{conn: conn} do
    # f = insert(:facility, name: "1", status: "Affiliated", step: 7)

    # batch = insert(
    #   :batch,
    #   batch_no: "Batch-101",
    #   facility_id: f.id,
    #   type: "HB",
    #   soa_ref_no: "HB23",
    #   soa_amount: "25",
    #   estimate_no_of_claims: "25",
    #   date_received: "2017-01-01",
    #   date_due: "2017-02-01",
    #   mode_of_receiving: "mode1",
    #   coverage: "Outpatient"
    # )

    # params = %{
    #   "facility_id" => "",
    #   "soa_fef_no" => "",
    #   "soa_amount" => "",
    #   "estimate_no_of_claims" => "10",
    #   "date_received" => "2017-01-01",
    #   "date_due" => "2017-02-01",
    #   "mode_of_receiving" => "mode2",
    #   "coverage" => "Outpatien"
    # }

    # conn = put(conn, batch_path(conn, :update_hb_batch, batch), batch: params, data: [], facility: [{f.name, f.id}])
    # assert html_response(conn, 200) =~ "Update HB Batch"
    # assert html_response(conn, 200) =~ batch.batch_no
    # assert html_response(conn, 200) =~ batch.facility_id
    # assert html_response(conn, 200) =~ batch.coverage
  # end
  #   conn = put(conn, batch_path(conn, :update_pf_batch, batch), batch: params, data: [], facility: [{f.name, f.id}])
  #   assert redirected_to(conn) == batch_path(conn, :edit_pf_batch, batch)
  # end

  # test "update_pf_batch returns error with invalid attrs", %{conn: conn} do
  #   f = insert(:facility, name: "1", status: "Affiliated", step: 7)
  #   p = insert(:practitioner, first_name: "test", last_name: "test")

  #   batch = insert(
  #     :batch,
  #     batch_no: "Batch-101",
  #     facility_id: f.id,
  #     practitioner_id: p.id,
  #     type: "PF",
  #     soa_ref_no: "HB23",
  #     soa_amount: "25",
  #     estimate_no_of_claims: "25",
  #     date_received: "2017-01-01",
  #     date_due: "2017-02-01",
  #     mode_of_receiving: "mode1",
  #     coverage: "Outpatient"
  #   )

  #   params = %{
  #     "facility_id" => "",
  #     "practitioner_id" => "",
  #     "soa_fef_no" => "123",
  #     "soa_amount" => "456",
  #     "estimate_no_of_claims" => "10",
  #     "date_received" => "2017-01-01",
  #     "date_due" => "2017-02-01",
  #     "mode_of_receiving" => "mode2",
  #     "coverage" => "Outpatient"
  #   }

  #   conn = put(conn, batch_path(conn, :update_pf_batch, batch), batch: params, data: [], facility: [{f.name, f.id}])
  #   assert html_response(conn, 200) =~ "Update PF Batch"
  #   assert html_response(conn, 200) =~ batch.batch_no
  #   assert html_response(conn, 200) =~ batch.facility_id
  #   assert html_response(conn, 200) =~ batch.practitioner_id
  #   assert html_response(conn, 200) =~ batch.coverage
  #   assert html_response(conn, 200) =~ batch.mode_of_receiving
  # end

  # test "render edit hb batch", %{conn: conn} do
  #   f = insert(:facility, name: "1", status: "Affiliated", step: 7)
  #   batch = insert(
  #     :batch,
  #     facility_id: f.id,
  #     type: "HB",
  #     soa_ref_no: "HB23",
  #     soa_amount: "25",
  #     estimate_no_of_claims: "25",
  #     date_received: "2017-01-01",
  #     date_due: "2017-02-01",
  #     mode_of_receiving: "mode1",
  #     batch_no: "Batch-101"
  #   )
  #   conn = get conn, batch_path(conn, :edit_hb_batch, batch)
  #   assert html_response(conn, 200) =~ "Update HB Batch"
  # end

  # test "update_hb_batch returns success with valid attrs", %{conn: conn} do
  #   f = insert(:facility, name: "1", status: "Affiliated", step: 7)

  #   batch = insert(
  #     :batch,
  #     batch_no: "Batch-101",
  #     facility_id: f.id,
  #     type: "HB",
  #     soa_ref_no: "HB23",
  #     soa_amount: "25",
  #     estimate_no_of_claims: "25",
  #     date_received: "2017-01-01",
  #     date_due: "2017-02-01",
  #     mode_of_receiving: "mode1",
  #     coverage: "Outpatient"
  #   )

  #   params = %{
  #     "facility_id" => f.id,
  #     "soa_fef_no" => "123",
  #     "soa_amount" => "456",
  #     "estimate_no_of_claims" => "10",
  #     "date_received" => "2017-01-01",
  #     "date_due" => "2017-02-01",
  #     "mode_of_receiving" => "mode2",
  #     "coverage" => "Outpatien"
  #   }

  #   conn = put(conn, batch_path(conn, :update_hb_batch, batch), batch: params, data: [], facility: [{f.name, f.id}])
  #   assert redirected_to(conn) == batch_path(conn, :edit_hb_batch, batch)
  # end

  # test "update_hb_batch returns error with invalid attrs", %{conn: conn} do
  #   f = insert(:facility, name: "1", status: "Affiliated", step: 7)

  #   batch = insert(
  #     :batch,
  #     batch_no: "Batch-101",
  #     facility_id: f.id,
  #     type: "HB",
  #     soa_ref_no: "HB23",
  #     soa_amount: "25",
  #     estimate_no_of_claims: "25",
  #     date_received: "2017-01-01",
  #     date_due: "2017-02-01",
  #     mode_of_receiving: "mode1",
  #     coverage: "Outpatient"
  #   )

  #   params = %{
  #     "facility_id" => "",
  #     "soa_fef_no" => "",
  #     "soa_amount" => "",
  #     "estimate_no_of_claims" => "10",
  #     "date_received" => "2017-01-01",
  #     "date_due" => "2017-02-01",
  #     "mode_of_receiving" => "mode2",
  #     "coverage" => "Outpatien"
  #   }

  #   conn = put(conn, batch_path(conn, :update_hb_batch, batch), batch: params, data: [], facility: [{f.name, f.id}])
  #   assert html_response(conn, 200) =~ "Update HB Batch"
  #   assert html_response(conn, 200) =~ batch.batch_no
  #   assert html_response(conn, 200) =~ batch.facility_id
  #   assert html_response(conn, 200) =~ batch.coverage
  # end

  test "submit_batch/2, submits a batch with no LOA attached", %{conn: conn} do
    insert(:coverage, name: "ACU", code: "ACU")
    f = insert(:facility, name: "1", status: "Affiliated", step: 7)
    batch = insert(
      :batch,
      batch_no: "Batch-101",
      facility_id: f.id,
      type: "HB",
      soa_ref_no: "HB23",
      soa_amount: "25",
      estimate_no_of_claims: "25",
      date_received: "2017-01-01",
      date_due: "2017-02-01",
      mode_of_receiving: "mode1",
      coverage: "Outpatient"
    )
    conn = post(conn, batch_path(conn, :submit_batch, batch))
    assert json_response(conn, 200) =~ "error"
  end

  test "submit_batch/2, submits a batch with LOA attached", %{conn: conn, authorization: authorization} do
    insert(:coverage, name: "ACU", code: "ACU")
    f = insert(:facility, name: "1", status: "Affiliated", step: 7)
    batch = insert(
      :batch,
      batch_no: "Batch-101",
      facility_id: f.id,
      type: "HB",
      soa_ref_no: "HB23",
      soa_amount: "25",
      estimate_no_of_claims: "25",
      date_received: "2017-01-01",
      date_due: "2017-02-01",
      mode_of_receiving: "mode1",
      coverage: "Outpatient"
    )
   insert(
      :batch_authorization,
      authorization_id: authorization.id,
      batch_id: batch.id,
      status: "Save"
    )
    conn = post(conn, batch_path(conn, :submit_batch, batch))
    assert json_response(conn, 200) =~ "success"
  end

  test "delete batch with valid batch id", %{conn: conn} do
    batch = insert(:batch)
    conn = delete(conn, batch_path(conn, :delete_batch, batch.id))
    assert json_response(conn, 200)
  end

  test "delete batch with invalid batch id", %{conn: conn} do
    assert_raise(FunctionClauseError, fn ->
      delete(conn, batch_path(conn, :delete_batch, Ecto.UUID.generate()))
    end)
  end

end
