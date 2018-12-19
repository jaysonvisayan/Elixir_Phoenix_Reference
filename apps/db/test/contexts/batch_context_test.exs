defmodule Innerpeace.Db.Base.BatchContextTest do
  import Innerpeace.Db.Base.BatchContext
  use Innerpeace.{
    Db.SchemaCase,
  }

  alias Innerpeace.Db.Schemas.{
    Batch
  }

 test "create_hb_batch/1 success" do
   user = insert(:user)
   insert(:sequence, number: "1000101", type: "batch_no")
   f = insert(:facility)
   params = %{
     "facility_id" => f.id,
     "type" => "hb",
     "soa_fef_no" => "123",
     "soa_amount" => "456",
     "estimate_no_of_claims" => "10",
     "date_received" => "2017-01-01",
     "date_due" => "2017-02-01",
     "mode_of_receiving" => "Mode1",
     "coverage" => "Inpatient",
     "soa_ref_no" => "12"
   }

   assert {:ok, %Batch{}} = create_hb_batch(params, user.id, nil)
 end

 test "create_pf_batch/1 success" do
   user = insert(:user)
   insert(:sequence, number: "1000101", type: "batch_no")
   f = insert(:facility)
   p = insert(:practitioner)
   params = %{
    "facility_id" => f.id,
    "practitioner_id" => p.id,
    "type" => "hb",
    "soa_fef_no" => "123",
    "soa_amount" => "456",
    "estimate_no_of_claims" => "10",
    "date_received" => "2017-01-01",
    "date_due" => "2017-02-01",
    "mode_of_receiving" => "Mode1",
    "coverage" => "Outpatient"
   }

   assert {:ok, %Batch{}} = create_pf_batch(params, user.id)
 end

 test "create_hb_batch/1 failed" do
   user = insert(:user)
   insert(:sequence, number: "1000101", type: "batch_no")
   insert(:facility)
   params = %{
    "soa_fef_no" => "123",
    "type" => "hb",
    "soa_amount" => "456",
    "estimate_no_of_claims" => "10",
    "date_received" => "2017-01-01",
    "date_due" => "2017-02-01",
    "mode_of_receiving" => "Mode1"
   }

   assert {:error, _changeset} = create_hb_batch(params, user.id, nil)
 end

 test "create_pf_batch/1 failed" do
   user = insert(:user)
   insert(:facility)
   params = %{
    "soa_fef_no" => "123",
    "type" => "hb",
    "soa_amount" => "456",
    "estimate_no_of_claims" => "10",
    "date_received" => "2017-01-01",
    "date_due" => "2017-02-01",
    "mode_of_receiving" => "Mode1"
   }

   assert {:error, _changeset} = create_pf_batch(params, user.id)
 end

 test "get_batch_no/1 success" do
  insert(:batch, batch_no: "017-R12345")

  refute is_nil(get_batch_no("017-R12345"))
 end

 test "get_batch_no/1 failed" do
  assert is_nil(get_batch_no("017-R12345"))
 end

 test "get_facility_address/1 success" do
   f = insert(:facility, line_1: "1")
   refute is_nil(get_facility_address(f.id))
 end

 test "get_facility_address/1 failed" do
   f = insert(:user)
   assert is_nil(get_facility_address(f.id))
 end



 test " get_practitioner_details/1 success" do
   p = insert(:practitioner, first_name: "test", last_name: "test")
   refute is_nil(get_practitioner_details(p.id))
 end

 test " get_practitioner_details/1 failed" do
   p = insert(:user)
   assert is_nil(get_practitioner_details(p.id))
 end

 test "submit_batch/1, submits a batch with no LOA Attached" do
   f = insert(:facility, name: "1", status: "Affiliated", step: 7)
    insert(:coverage, name: "ACU", description: "ACU", code: "ACU")
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

   assert submit_batch(batch.id) == {:error, "Please add LOA first."}
 end

 test "submit_batch/1, submits a batch with LOA Attached" do
    insert(:coverage, name: "ACU", description: "ACU", code: "ACU")
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
   assert {:ok, batch} = submit_batch(batch.id)
   assert batch.status == "Submitted"
 end

 test "delete_batch/1, deletes batch" do
   batch = insert(:batch)
   assert {:ok, _batch} = delete_batch(batch.id)
   assert is_nil(get_batch!(batch.id))
 end

 test "delete_batch_comments/1, deletes all comments of the given batch" do
   batch_comment = insert(:batch_comment)
   assert {_count, nil} = delete_batch_comments(batch_comment.batch_id)
 end

end
