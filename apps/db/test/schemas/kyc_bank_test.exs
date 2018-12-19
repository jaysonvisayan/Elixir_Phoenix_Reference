defmodule Innerpeace.Db.Schemas.KycBankTest do
  use Innerpeace.Db.SchemaCase

  alias Innerpeace.Db.Schemas.KycBank

  test "changeset with valid attributes" do
    member = insert(:member)
    params = %{
      country: "sample1",
      city: "sample1" ,
      citizenship: "sample1",
      civil_status: "sample1",
      mother_maiden: "sample1",
      tin: "123456123456",
      sss_number: "123456123456",
      unified_id_number: "123123123111",
      educational_attainment: "sample1",
      position_title: "sample1",
      occupation: "sample1",
      source_of_fund: "sample1",
      company_name: "sample1",
      company_branch: "sample1",
      nature_of_work: "sample1",
      member_id: member.id,
      id_card: "sample",
      mm_first_name: "test1",
      mm_middle_name: "test2",
      mm_last_name: "test3"
    }

    changeset = KycBank.changeset(%KycBank{}, params)
    assert changeset.valid?
  end


  test "changeset with invalid attributes" do
    member = insert(:member)
    params = %{
      country: "sample1",
      city: "sample1" ,
      citizenship: "sample1",
      civil_status: "sample1",
      mother_maiden: "sample1",
      tin: "sample1",
      sss_number: "sample1",
      unified_id_number: "sample1",
      educational_attainment: "sample1",
      position_title: "sample1",
      occupation: "sample1",
      source_of_fund: "sample1",
      company_name: "sample1",
      company_branch: "sample1",
      member_id: member.id
    }

    changeset = KycBank.changeset(%KycBank{}, params)
    refute changeset.valid?
  end

end

